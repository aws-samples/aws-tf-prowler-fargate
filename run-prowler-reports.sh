#!/bin/bash -e
#
# Run Prowler against All AWS Accounts in an AWS Organization

# Validate Values from Environment Variables Created By Terraform
echo "S3BUCKET:       $S3BUCKET"
echo "S3ACCOUNT:      $S3ACCOUNT"
echo "ROLE:           $ROLE"

# Create the Prowler Output Directory if it doesn't exist
ls ./output
if [ $? != 0 ]; then mkdir ./output; fi

# Create the Prowler Config Directory if it doesn't exist
ls ./config
if [ $? != 0 ]; then mkdir ./config; fi

# CleanUp Last Ran Prowler Reports, as they are already stored in S3.
rm -rf ./output/*.csv
rm -rf ./output/*.json
rm -rf ./output/*.html

# Function to unset AWS Profile Variables
unset_aws() {
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}
unset_aws

# Find THIS Account AWS Number
CALLER_ARN=$(aws sts get-caller-identity --output text --query "Arn")
PARTITION=$(echo "$CALLER_ARN" | cut -d: -f2)
THISACCOUNT=$(echo "$CALLER_ARN" | cut -d: -f5)
echo "THISACCOUNT:    $THISACCOUNT"
echo "PARTITION:      $PARTITION"

# Function to Assume Role to THIS Account & Create Session
this_account_session() {
    unset_aws
    role_credentials=$(aws sts assume-role --role-arn arn:"$PARTITION":iam::"$THISACCOUNT":role/"$ROLE" --role-session-name ProwlerRun --output json)
    AWS_ACCESS_KEY_ID=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
    AWS_SECRET_ACCESS_KEY=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
    AWS_SESSION_TOKEN=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

# Find AWS Master Account
this_account_session
AWSMASTER=$(aws organizations describe-organization --query Organization.MasterAccountId --output text)
echo "AWSMASTER:      $AWSMASTER"

# Function to Assume Role to Master Account & Create Session
master_account_session() {
    unset_aws
    role_credentials=$(aws sts assume-role --role-arn arn:"$PARTITION":iam::"$AWSMASTER":role/"$ROLE" --role-session-name ProwlerRun --output json)
    AWS_ACCESS_KEY_ID=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
    AWS_SECRET_ACCESS_KEY=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
    AWS_SESSION_TOKEN=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

# Lookup All Accounts in AWS Organization
master_account_session
ACCOUNTS_IN_ORGS=$(aws organizations list-accounts --query Accounts[*].Id --output text)

# Function to Assume Role to S3 Account & Create Session
s3_account_session() {
    unset_aws
    role_credentials=$(aws sts assume-role --role-arn arn:"$PARTITION":iam::"$S3ACCOUNT":role/"$ROLE" --role-session-name ProwlerRun --output json)
    AWS_ACCESS_KEY_ID=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
    AWS_SECRET_ACCESS_KEY=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
    AWS_SESSION_TOKEN=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

prowler_get_run_parameters() {
    s3_account_session
    #Obtain Prowler Config
    aws s3 cp s3://"$S3BUCKET"/config/prowler-config.txt ./config/

    # Get the scan group details from the Prowler config file
    prowler_scan_group=$(grep -i -e "^group=.*$" ./config/prowler-config.txt | sed 's/group=//g' | xargs)

    prowler_scan_group_word_count=$(echo $prowler_scan_group | wc -w)

    if [ $prowler_scan_group_word_count == 0 ];then 
        echo "[Prowler Alert]: Your config file doesn't have an scan groups listed. Defaulting to cislevel2";
        prowler_scan_group="cislevel2";
    fi

    # Get the output formats from the Prowler config file
    prowler_output_format=$(grep -i -e "^format=.*$" ./config/prowler-config.txt | sed 's/format=//g' | xargs | sed -e 's/[[:space:]]*//g')

    prowler_output_format_word_count=$(echo $prowler_output_format | wc -w)

    if [ $prowler_output_format_word_count == 0 ];then 
        echo "[Prowler Alert]: Your config file doesn't have an output format listed. Defaulting to csv";
        prowler_output_format="csv";
    fi

    echo "[Prowler Config] Selected Group $prowler_scan_group \r\n"
    echo "[Prowler Config] Selected Output Format $prowler_output_format \r\n"

    export prowler_scan_group prowler_output_format 
}

# Run Prowler against Accounts in AWS Organization
echo "AWS Accounts in Organization"
echo "$ACCOUNTS_IN_ORGS"
PARALLEL_ACCOUNTS="1"
prowler_get_run_parameters

for accountId in $ACCOUNTS_IN_ORGS; do
    # shellcheck disable=SC2015
    test "$(jobs | wc -l)" -ge $PARALLEL_ACCOUNTS && wait || true
    {
        START_TIME=$SECONDS
        # Unset AWS Profile Variables
        unset_aws
        # Run Prowler
        echo -e "Assessing AWS Account: $accountId, using Role: $ROLE on $(date)"
        
        # remove -g cislevel for a full report and add other formats if needed
        ./prowler -R "$ROLE" -A "$accountId" -g "$prowler_scan_group" -M "$prowler_output_format"

        echo "Report stored locally at: prowler/output/ directory"
        TOTAL_SEC=$((SECONDS - START_TIME))
        echo -e "Completed AWS Account: $accountId, using Role: $ROLE on $(date)"
        printf "Completed AWS Account: $accountId in %02dh:%02dm:%02ds" $((TOTAL_SEC / 3600)) $((TOTAL_SEC % 3600 / 60)) $((TOTAL_SEC % 60))
        echo ""

    } &
done

# Wait for All Prowler Processes to finish
wait

# Upload Prowler Report to S3
echo "Prowler Assessment Completed. Copying report file to S3 $S3BUCKET."
s3_account_session
aws s3 mv ./output/ s3://"$S3BUCKET"/reports/ --recursive --include "*.html" --acl bucket-owner-full-control

echo "Assessment reports successfully copied to S3 bucket"

# Final Wait for All Prowler Processes to finish
wait
echo "Prowler Assessments Completed"

# Unset AWS Profile Variables
unset_aws