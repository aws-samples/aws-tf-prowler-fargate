# Perform security assessment in AWS Organizations using Prowler on AWS Fargate and Terraform

## Description

This [Terraform](https://www.terraform.io/) module helps you assess your multi-account environment in [AWS Organizations](https://aws.amazon.com/organizations/) using [Prowler](https://github.com/toniblyx/prowler) security assessment tool  deployed on [AWS Fargate](https://aws.amazon.com/fargate/). It assesses all accounts using a time-based schedule expression in [Amazon CloudWatch](https://aws.amazon.com/cloudwatch/), creates assessment reports in CSV format, and stores them in an [Amazon Simple Storage Service (S3)](https://aws.amazon.com/s3/) bucket.

With AWS Fargate, there are no upfront costs and you pay only for the resources you use. You pay for the amount of vCPU, memory, and storage resources consumed by your containerized Prowler application running on AWS Fargate.

## Features

- Programmatically assess the security posture of your accounts in AWS Organizations using Terraform Infrastructure as Code.
- Send Prowler findings to S3 Bucket.

## Solution overview

The solution works as follows:

- A time-based CloudWatch Event starts a Fargate task hosting Prowler on a schedule you define.
- Fargate pulls a Prowler Docker image from Amazon Elastic Container Registry (ECR).
- Prowler scans your AWS infrastructure and assumes IAM roles across the accounts.
- Prowler writes the scan results to CSV files in an S3 bucket.

## Prerequisites

The following prerequisites are required to deploy the solution:


1. A strong understanding of cross account trust relationship policies and IAM policies.

2. Intermediate level knowledge of Terraform. 

3. Access to an AWS Organizations privileged user or role that can deploy roles into your organizations sub-accounts.

4. Network Requirements (you will need the Subnet and VPC IDs in your input variables.):

5. A VPC with 1 subnet that has access to the Internet; AND

6. A security group that allows outbound access on Port 443 (HTTPS).

7. Download and set up Terraform. Refer to the official Terraform instructions to get started.

8. Make sure that your Terraform environment is able to assume an administrative role to implement the resources described in this blog across your member and prowler deployment accounts.

9. Install Git

10. Install latest version of the AWS CLI or use the AWS CloudShell. To use the AWS CLI, you must make sure that you have profiles to assume roles across your accounts. You can get more information about creating CLI configuration files in the AWS CLI user guide.

    * Note: The docker image will need to be built and pushed to the ecr outside of CloudShell. There isn't support for running Docker in CloudShell currently.

11. Decide on the appropriate account in which to deploy the Prowler solution (ECS task). AWS recommends deploying the solution in the security account.

12. Get and install Docker where you plan to build the Prowler container image.
    * **If using a Mac with the new Apple Silicon M processor**, you will need to use the [experimental docker feature](https://blog.jaimyn.dev/how-to-build-multi-architecture-docker-images-on-an-m1-mac/) to build the x86 image.

13. Clone the AWS Samples Github repository:

    ```
    git clone https://github.com/aws-samples/aws-tf-prowler-fargate.git
    ```

## Module Components

1.  [main.tf](./main.tf)
    * Creates an Amazon ECR Cluster to run the Prowler container.
    * Creates a Prowler task definition for AWS Fargate.
    * Enables Amazon CloudWatch Log Group to visualize Prowler execution logs.
    * Implements AWS IAM role to trigger container tasks via Amazon EventBridge rule.
    * Allows an Amazon EventBridge rule to schedule and invoke the Prowler container using a [rate or cron expression](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html).

2.  [outputs.tf](./outputs.tf)
    * Defines the [Terraform output](https://www.terraform.io/docs/language/values/outputs.html) values of this Terraform module.

3.  [provider.tf](./provider.tf)
    * Defines the [Terraform provider](https://www.terraform.io/docs/language/providers/index.html) to interact with AWS cloud and/or Terraform state files.

4.  [variables.tf](./variables.tf)
    * Defines the input variables for this Terraform module.

5.  [run-prowler-reports.sh](./run-prowler-reports.sh)
    * Refer to the script for line-by-line documentation of each command.
    * Loops through all AWS Accounts in AWS Organization, and by default, runs Prowler as follows:
        * -R: used to specify Cross-Account role for Prowler to assume to run its assessment.
        * -A: used to specify AWS Account number for Prowler to run assessment against.
        * -g cislevel2: used to specify cislevel2 checks for Prowler to assess
        * -M csv: used to output Prowler reports to CSV files.

6. [Dockerfile](./Dockerfile)
    * Text document that contains all the commands to build Prowler image. 

7. [prowler-config.txt](./config/prowler-config.txt)
    * Text document that contains the Prowler run configuration that is pulled by the ECS task once it is provisioned. This tells the Prowler tool what scans to perform and the output format of the report. 

## Installation steps

### Download the Terraform code to an environment configured to access the AWS Organizations Management and member accounts.

    ``` 
        git clone https://github.com/aws-samples/aws-tf-prowler-fargate
    ```

### Create an Amazon ECR Repository
    
Perform the following steps in your Prowler deployment account (for example, Security account):
    
1. Create an Amazon ECR repository using the [AWS CloudShell](https://aws.amazon.com/cloudshell/).

    ```    
    aws ecr create-repository \
    --repository-name prowler-repo \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=KMS
    ```

2. Make a note of the ECR repository URI. Format: 01234567890.dkr.ecr.us-east-1.amazonaws.com/prowler-repo.

3. To list your ECR repositories use the following command:

    ```
    aws ecr describe-repositories
    ```

### Update Prowler Configuration File

The primary prowler configuration for running the scans is contained in [prowler-config.txt](./config/prowler-config.txt). You can customize your scan parameters to ensure Prowler is running the appropriate checks for your environment. 

Update the variables in [prowler-config.txt](./config/prowler-config.txt) to configure the checks prowler runs (-g cislevel2) and the report output format (-M csv).

A list of available groups can be found here. Note you cannot run multiple groups simultaneously.

A list of supported output formats (you can select multiple): csv,json,json-asff,html

1. **Example 1:** Run Prowler checks from the extras group and output the report to CSV.

    Edit the following in prowler-config.txt:
        
    ```
    PROWLER_SCAN_GROUP=extras

    PROWLER_OUTPUT_FORMAT=csv
    ```

2. **Example 2:** Run Prowler checks from the cislevel2 group and output the report to CSV, JSON, and HTML.

    Edit the following in prowler-config.txt:

    ```
    PROWLER_SCAN_GROUP=cislevel2

    PROWLER_OUTPUT_FORMAT=csv,json,html
    ```



### Build and push the Docker image to ECR.

1. Obtain ECR login credentials

    MacOS or Linux
    ```
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 01234567890.dkr.ecr.us-east-1.amazonaws.com
    ```
    Windows
    ```
    (Get-ECRLoginCommand).Password | docker login --username AWS --password-stdin 111111111111.dkr.ecr.us-west-2.amazonaws.com
    ```

2. Build Prowler Docker Image

    MacOS, Linux, Windows
    ```
    docker build --platform=linux/amd64 --no-cache -t prowler:latest -f Dockerfile .
    ```


3. Tag Prowler Docker Image
    
    MacOS, Linux, Windows

    ```
    docker tag prowler-repo:latest 111111111111.dkr.ecr.us-west-2.amazonaws.com/prowler-repo:latest
    ```

4. Push Prowler Docker Image to ECR

    MacOS, Linux, Windows

    ```
    docker push 01234567890.dkr.ecr.us-east-1.amazonaws.com/prowler:latest
    ```

### Update Terraform Configuration

To implement Prowler in a designated Prowler deployment account, update the [main.tf](./main.tf) file in the solution's root directory with your input variables referencing [variables.tf](./variables.tf) (Example 1) or hard code the variables directly into [main.tf](./main.tf) (Example 2)

1. **Example 1:**
If you use the format below you will need to hard code the variables in variables.tf or you will need to provide them in a myvariables.tfvars file and pass it into the terraform apply command as follows. 

    ```
    terraform apply -var-file [myvariables-example.tfvars](./myvariables-example.tfvars)
    ```
    ```
        module "prowler_ecs_instance_deployment" {
          source = "./modules/aws-tf-prowler-fargate"
          providers = {
            aws = aws.prowler_deployment_account
          }
          
          # The AWS account id for the account that will run Prowler.
          deployment_accountid = var.deployment_accountid
          # URI to the repository with the Prowler container image.
          ecr_image_uri = var.ecr_image_uri
          # Security Group must allow outbound access on Port 443 (HTTPS).
          prowler_container_sg_id = var.prowler_container_sg_id
          # VPC must have internet access.
          prowler_container_vpc_subnet_id = var.prowler_container_vpc_subnet_id

          # Optional - Uncomment and specify schedule to override the default schedule (every 7 days) defined in variables.tf.
          # prowler_schedule_task_expression = var.prowler_schedule_task_expression

          tags = var.tags
        }
    ```

2. **Example 2:**

    ```
    module "prowler_ecs_instance_deployment" {
      source = "./modules/aws-tf-prowler-fargate"
      providers = {
        aws = aws.prowler_deployment_account
      }
      
      # The AWS account id for the account that will run Prowler.
      deployment_accountid = "123456789011"
      # URI to the repository with the Prowler container image.
      ecr_image_uri = "123456789011.dkr.ecr.us-west-2.amazonaws.com/prowler-repo"
      # Security Group must allow outbound access on Port 443 (HTTPS).
      prowler_container_sg_id = "sg-1111fea111e1234561"
      # VPC must have internet access.
      prowler_container_vpc_subnet_id = "subnet-11b11f1edd1a11e1f"

      # Optional - Uncomment and specify schedule to override the default schedule (every 7 days) defined in variables.tf.
      # prowler_schedule_task_expression = var.prowler_schedule_task_expression

      tags = var.tags
    }
    ```

### Deploy Terraform code

Modify the [main.tf](./main.tf) file in the root module using a text editor and update the source variable parameters, deployment account id, ECR image URI (from step 3), VPC security group id and subnet id, and the CloudWatch Event [Schedule Expression Rule](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html). The `source` argument in a [module block](https://www.terraform.io/docs/language/modules/syntax.html) tells Terraform where to find the source code for the desired child module. Typical sources include Terraform Registry, local paths, S3 buckets, and many more. See the documentation on [Terraform Module Sources](https://www.terraform.io/docs/language/modules/sources.html) for additional information.
    
* Now that you have updated the script with your variable configuration, you can initialize the directory. Initializing a configuration directory downloads and installs the AWS provider, which is defined in the configuration:

    ``` 
        terraform init
    ```
    You should see a message that says `Terraform has been successfully initialized!` and the version of the provider that was installed.

* You should format and validate your configuration. The `terraform fmt` command automatically updates configurations in the current directory for readability and consistency. You can also make sure that your configuration is syntactically valid and consistent using the `terraform validate` command:

    ``` 
        terraform fmt
        terraform validate
    ```

* Apply the configuration to create the infrastructure:

    ``` 
        terraform apply
    ```
    OR
    
    If you are passing in a local variables file you can pass them to terraform apply as follows:

    ```
    terraform apply -var-file myvariables-example.tfvars
    ```

* Before applying any configuration changes, Terraform prints out the execution plan to describe the actions that Terraform will take to update your infrastructure. Once prompted, you will need to type `yes` to confirm that the plan can be run.

* Take note of the S3 Prowler Bucket name once it’s created. You will need the bucket name when deploying the cross-account role in the following steps.

### Deploy the Prowler Cross-Account IAM Role

**Do NOT deploy this role into the prowler deployment account (the account that will be hosting your prowler instance, e.g. security account).** The main Prowler module that deploys the ECS instance and task also creates a slightly modified version of the prowler role in the deployment account.

* Deploy the  [aws-tf-iam-role](./modules/aws-tf-iam-role/main.tf) module to your AWS Organizations Management account.

* Deploy the [aws-tf-iam-role](./modules/aws-tf-iam-role/main.tf)  module to your AWS Organizations member accounts to be assessed by Prowler. 


1. You will need to comment out the [aws-tf-prowler-fargate](./modules/aws-tf-prowler-fargate/main.tf) module block from [main.tf](./main.tf). 

    ```
    ## Call Module to Deploy the Prowler ECS Instance and Role
    # module "prowler_ecs_instance_deployment" {
    #   source = "./modules/aws-tf-prowler-fargate"
    #   providers = {
    #     aws = aws.prowler_deployment_account
    #   }
    
    #   # The AWS account id for the account that will run Prowler.
    #   deployment_accountid = var.deployment_accountid
    #   # URI to the repository with the Prowler container image.
    #   ecr_image_uri = var.ecr_image_uri
    #   # Security Group must allow outbound access on Port 443 (HTTPS).
    #   prowler_container_sg_id = var.prowler_container_sg_id
    #   # VPC must have internet access.
    #   prowler_container_vpc_subnet_id = var.prowler_container_vpc_subnet_id

    #   # Optional - Uncomment and specify schedule to override the default schedule (every 7 days) defined in variables.tf.
    #   # prowler_schedule_task_expression = var.prowler_schedule_task_expression

    #   tags = var.tags
    # }
    ```

2. Update the [aws-tf-iam-role](./modules/aws-tf-iam-role/) module block for prowler_iam_cross_account_role_# in [main.tf](./main.tf) in the root directory. The code should look similar to the examples below:
   
    **Example 1:**
    
    The prowler_s3 bucket should be the name of the bucket that was deployed by the [aws-tf-prowler-fargate](./modules/aws-tf-prowler-fargate/main.tf) module.

    ```
    module "prowler_iam_cross_account_role_1" {
    source = "./modules/aws-tf-iam-role"
    providers = {
        aws = aws.prowler_account_scan_account_1
    }
    
    # The AWS account id for the account that will run Prowler.
    deployment_accountid = var.deployment_accountid
    prowler_s3 = "prowler-1111111111-us-west-2"

    }
    ```

    **Example 2:**
    ```
    module "prowler_iam_cross_account_role_2" {
    source = "./modules/aws-tf-iam-role"
    providers = {
        aws = aws.prowler_account_scan_account_2
    }
    
    # The AWS account id for the account that will run Prowler.
    deployment_accountid = "222222222222"
    prowler_s3 = "prowler-222222222222-us-west-2"

    }
    ```

3.  Update the [providers.tf](./providers.tf) file to deploy to multiple accounts. 

    Specific guidance on multi-account deployment is not in scope for this article since this can be accomplished through several methods depending on your particular environment, configuration, and personal preference. Please see the official Terraform documentation on multi-account deployments with Terraform. The examples below are provided as a reference point.

    Example of [providers.tf](./providers.tf) configuration to deploy to multiple accounts.

    ```
    # Prowler Scan Account 1
    provider "aws" {
    region = var.region_primary
    alias   = "prowler_account_scan_account_1"
    
    assume_role {
        role_arn     = "arn:aws:iam::123456789012:role/ROLE_NAME"
        session_name = "deploy_prowler_role"
        #external_id  = "EXTERNAL_ID"
    }

    }

    # Prowler Scan Account 2
    provider "aws" {
    region = var.region_primary
    alias   = "prowler_account_scan_account_2"
    
    assume_role {
        role_arn     = "arn:aws:iam::123456789012:role/ROLE_NAME"
        session_name = "deploy_prowler_role"
        #external_id  = "EXTERNAL_ID"
    }

    }
    ```



4. Alternatively, this role can be deployed with CloudFormation StackSets. The CloudFormation template file is available [here](./extras/aws-tf-iam-role.yaml).

### Manually run the container task

By default, the Prowler task is configured to run **every 7 days** using the CloudWatch Event Rule. You can trigger a manual run of the task using the following command. Ensure you replace the value of the `subnet-0111111111111111111` with your subnet id. In addition, the task requires Internet connection to download the Prowler source code.

```
    aws ecs run-task --launch-type FARGATE \
    --task-definition prowler-security-assessment \
    --cluster prowler-security-assessment-cluster \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-0111111111111111111],assignPublicIp=ENABLED}"
```

You have successfully implemented the Prowler security assessment tool on AWS Fargate using Terrraform. You should see see logs from the container tasks in your ECS task definition.
## ![](./images/aws-tf-prowler-fargate.png)

### Check Prowler Scan Status

Utilize CloudWatch Insights to find the current status of your Prowler scan.

1. Login to the AWS Console and navigate the CloudWatch.

2. From the CloudWatch main page navigate to Logs then Logs Insights in the lefthand menu.

3. On the Logs Insights page select the Prowler log group from the dropdown menu.

4. Select the appropriate timeframe for your search.

5. Enter one of the queries below.

    * Find Scan Start Time
    ```
    fields @message | parse @message “Assessing AWS Account: *, *” as @account_id, @starttime | filter ispresent(@account_id)| sort @account_id desc | display @account_id, @timestamp, @starttime  
    ```

    * Find Scan End Time
    ```
    fields @message
    | parse @message “Completed AWS Account: * in *” as @account_id, @endtime
    | filter ispresent(@account_id)
    | sort @account_id desc
    | display @account_id, @timestamp, @endtime
    ```
    * Regex to Extract Scan Start and End Times
    ```
    fields @message
    | parse @message /Assessing AWS Account: (?<account_id_start>[0-9]{12}), using Role: prowler-sec-assessment-role on (?<start_time>.*)|Completed AWS Account: (?<account_id_completed>[0-9]{12}) in (?<end_time>.+)/
    | sort @account_id_start asc
    ```

## Related Resources

Prowler supports native integration to send findings to AWS Security Hub. This integration allows Prowler to import its findings to AWS Security Hub for a comprehensive view which aggregates, organizes, and prioritizes your security alerts or findings. Refer to the [Security Hub Integration](https://github.com/prowler-cloud/prowler#security-hub-integration) for further information.



## Provider Requirements

All provider requirements can be found in [providers.tf](./providers.tf).


## Resources

| Name                                                  | Type         |
| ---------                                             |----          |
| aws_iam_role                                          | Resource     |
| aws_iam_role_policy                                   | Resource     |
| aws_iam_role_policy_attachment                        | Resource     |
| aws_s3_bucket                                         | Resource     |
| aws_s3_bucket_versioning                              | Resource     |
| aws_s3_bucket_acl                                     | Resource     |
| aws_s3_bucket_server_side_encryption_configuration    | Resource     |
| aws_s3_bucket_public_access_block                     | Resource     |
| aws_s3_bucket_policy                                  | Resource     |
| aws_ecs_cluster                                       | Resource     |
| aws_ecs_task_definition                               | Resource     |
| aws_cloudwatch_log_group                              | Resource     |
| aws_cloudwatch_event_rule                             | Resource     |
| aws_cloudwatch_event_target                           | Resource     |


## Input Variables

All variable details can be found in [tf-prowler-aws-fargate/variables.tf](variables.tf). Refer to the file for default variable values.

| Variable Name               | Description                                                             | Required  |
| -------------               | -----------                                                             | --------  |
| `bucket`                    | The name of the bucket.                                                 | Yes       |
| `inbound_tags`              | Tag map to be applied to all taggable resources created by this module. | Yes       |
| `kms_master_key_id`         | The AWS KMS master key ID used for SSE-KMS encryption.                  | Yes       |
| `ecs_cluster_name`          | AWS Fargate Cluser Name.                                                | Yes       |
| `ecs_task_definition_name`  | Unique ECS Task Definition Name.                                        | Yes       |
| `ecs_task_execution_arn`    | Name of the IAM role that allows Fargate to publish logs to CloudWatch and to download Prowler image from Amazon ECR | No |
| `ecs_task_role_name`        | Name of the IAM role with the permissions that Prowler needs to complete its scans.  | Yes |
| `ecs_task_role_arn`         | Arn of the IAM role with the permissions that Prowler needs to complete its scans.   | Yes |
| `fargate_task_cpu`          | CPU Reservation for AWS Fargate Task.                                    | Yes       |
| `fargate_memory`            | Memory Reservation for AWS Fargate Task.                                 | Yes       |
| `ecr_image_uri`             | URI Path of the Prowler Docker Image - Preferably from ECR.              | Yes       |
| `container_name`            | Name of the Container within AWS Fargate.                                | Yes       |
| `cwe_log_prefix`            | Prefix for CloudWatch Event Log Group.                                   | Yes       |
| `reporting_bucket`          | Name of the S3 bucket to store Prowler reports.                          | Yes       |
| `reporting_bucket_account_id` | Account ID of the S3 bucket to store prowler reports.                  | Yes       |
| `prowler_schedule_task_expression` | Schedule Expression to run the Prowler AWS Fargate Task.          | Yes       |
| `prowler_scheduled_task_event_role`| Name of the IAM Role for the CloudWatch Event Task Scheduler for AWS Fargate. | Yes       |
| `fargate_platform_version`  | FARGATE Platform Version.                                                | Yes       |
| `prowler_container_sg_id`   | Prowler container Security Group ID.                                     | Yes       |
| `prowler_container_vpc_subnet_id`  | Prowler container Subnet ID.                                      | Yes       |
| `log_retention_in_days`     | Number of days container task logs will be retained in CloudWatch.       | Yes       |
| `assign_container_public_ip`| Assign public IP to the container.                                       | Yes       |
| `tags`                      | A map of tags (key-value pairs) passed to resources.                     | Yes       |



## Outputs

All output details can be found in [outputs.tf](./outputs.tf).

| Output Name               | Description                                |
| -------------             | -----------                                |
| `ecs_cluster_arn`         | ARN of the AWS Fargate Cluster             |
| `ecs_task_definition`     | ARN of the ECS Task Definition             |
| `s3_bucket`               | ARN of the S3 Bucket                       |
| `iam_role`                | ARN of the Prowler role                    |
| `cloudwatch_log_group`    | ARN of the Amazon CloudWatch Log Group     |


## Changelog

A complete Changelog history can be found in [CHANGELOG.md](./CHANGELOG.md).

# Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.
