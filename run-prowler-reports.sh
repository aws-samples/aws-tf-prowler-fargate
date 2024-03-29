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

# Function to Assume Role to S3 Account & Create Session
s3_account_session() {
    unset_aws
    role_credentials=$(aws sts assume-role --role-arn arn:"$PARTITION":iam::"$S3ACCOUNT":role/"$ROLE" --role-session-name ProwlerRun --output json)
    AWS_ACCESS_KEY_ID=$(echo "$role_credentials" | jq -r .Credentials.AccessKeyId)
    AWS_SECRET_ACCESS_KEY=$(echo "$role_credentials" | jq -r .Credentials.SecretAccessKey)
    AWS_SESSION_TOKEN=$(echo "$role_credentials" | jq -r .Credentials.SessionToken)
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}


prowler_get_config() {
    s3_account_session
    #Obtain Prowler Config
    aws s3 cp s3://"$S3BUCKET"/config/prowler-config.txt ./config/

    # Get the scan group details from the Prowler config file
    PROWLER_SCAN_GROUP=$(grep -i -e "^PROWLER_SCAN_GROUP=.*$" ./config/prowler-config.txt | sed 's/PROWLER_SCAN_GROUP=//g' | sed -e 's/[[:space:]]*//g')
    echo "[Prowler Config] Selected Group $PROWLER_SCAN_GROUP."

    prowler_scan_group_word_count=$(echo $PROWLER_SCAN_GROUP | wc -w)

    if [ $prowler_scan_group_word_count == 0 ];then 
        echo "[Prowler Config]: Your config file doesn't have an scan groups listed. Defaulting to cislevel2";
        PROWLER_SCAN_GROUP="cislevel2";
    fi

    # Get the output formats from the Prowler config file
    PROWLER_OUTPUT_FORMAT=$(grep -i -e "^PROWLER_OUTPUT_FORMAT=.*$" ./config/prowler-config.txt | sed 's/PROWLER_OUTPUT_FORMAT=//g' | sed -e 's/[[:space:]]*//g')
    echo "[Prowler Config] Selected Output Format $PROWLER_OUTPUT_FORMAT."

    prowler_output_format_word_count=$(echo $PROWLER_OUTPUT_FORMAT | wc -w)

    if [ $prowler_output_format_word_count == 0 ];then 
        echo "[Prowler Config]: Your config file doesn't have an output format listed. Defaulting to csv";
        PROWLER_OUTPUT_FORMAT="csv";
    fi
    
    export PROWLER_SCAN_GROUP
    export PROWLER_OUTPUT_FORMAT

}

# Get the Prowler Run Variables
prowler_get_config


# Lookup All Accounts in AWS Organization
master_account_session
ACCOUNTS_IN_ORGS=$(aws organizations list-accounts --query Accounts[*].Id --output text)


# Run Prowler against Accounts in AWS Organization
echo "AWS Accounts in Organization"
echo "$ACCOUNTS_IN_ORGS"
PARALLEL_ACCOUNTS="1"

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
        ./prowler -R "$ROLE" -A "$accountId" -g "$PROWLER_SCAN_GROUP" -M "$PROWLER_OUTPUT_FORMAT"

        echo "Report stored locally at: prowler/output/ directory"
        TOTAL_SEC=$((SECONDS - START_TIME))
        echo -e "Completed AWS Account: $accountId, using Role: $ROLE on $(date)"
        printf "Completed AWS Account: $accountId in %02dh:%02dm:%02ds" $((TOTAL_SEC / 3600)) $((TOTAL_SEC % 3600 / 60)) $((TOTAL_SEC % 60))
        echo ""

        # Upload Prowler Report to S3
        echo "Prowler Assessment Completed for $accountId. Copying report file to S3 $S3BUCKET."
        s3_account_session
        aws s3 mv ./output/ s3://"$S3BUCKET"/reports/ --recursive --include "*.html" --acl bucket-owner-full-control
        echo "Assessment reports for $accountId successfully copied to S3 bucket"
    } &
done

# Wait for All Prowler Processes to finish
#wait


# Final Wait for All Prowler Processes to finish
wait
echo "Prowler Assessments Completed"

# Unset AWS Profile Variables
unset_aws