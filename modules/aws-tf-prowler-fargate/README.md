# `aws-tf-prowler-fargate/aws-tf-prowler-fargate`

## Description

This Terraform module implements the resources required to install [Prowler](https://github.com/prowler-cloud/prowler) security assessment tool on [AWS Fargate](https://aws.amazon.com/fargate/) so that you can assess your multi-account environment in [AWS Organizations](https://aws.amazon.com/organizations/). It should be deployed to your delegated Prowler deployment account.

## Module Components
1.  [main.tf](./main.tf)
    * Creates an IAM role assumed by Prowler deployment account.
    * Creates an [Amazon Simple Storage Service (S3)](https://aws.amazon.com/s3/) bucket to store Prowler reports.
    * Creates ECS Fargate task to run Prowler.
    * Creates CloudWatch log group to store ECS execution logs.

2.  [outputs.tf](./outputs.tf)
    * Defines the [Terraform output](https://www.terraform.io/docs/language/values/outputs.html) values of this Terraform module.

4.  [variables.tf](./variables.tf)
    * Defines the input variables for this Terraform module.

6. [data.tf](./data.tf)
    * Defines the IAM policy document for the Prowler role and S3 bucket policy permissions.

## Resources

| Name                                                  | Type         |
| ---------                                             |----          |
| aws_s3_bucket                                         | Resource     |
| aws_s3_bucket_versioning                              | Resource     |
| aws_s3_bucket_acl                                     | Resource     |
| aws_s3_bucket_server_side_encryption_configuration    | Resource     |
| aws_s3_bucket_public_access_block                     | Resource     |
| aws_s3_bucket_policy                                  | Resource     |
| aws_ecs_cluster                                       | Resource     |
| aws_ecs_task_definition                               | Resource     |
| aws_iam_role                                          | Resource     |
| aws_iam_policy                                        | Resource     |
| aws_iam_policy_attachment                             | Resource     |
| aws_cloudwatch_log_group                              | Resource     |
| aws_cloudwatch_event_rule                             | Resource     |
| aws_cloudwatch_event_target                           | Resource     |

## Input Variables

All variable details can be found in [aws-tf-prowler-fargate/aws-tf-prowler-fargate](aws-tf-prowler-fargate.tf). Refer to the file for default variable values.

| Variable Name                         | Description                                                                     | Required  |
| -------------                         | -----------                                                                     | --------  |
| `deployment_accountid`                | The AWS Account Id to deploy Prowler                                            | Yes       |
| `prowler_iamrole_name`                | IAM role name to assign to prowler cross-account role                           | Yes       |
| `ecs_cluster_name`                    | ECS Fargate Cluser Name                                                         | Yes       |
| `ecs_task_definition_name`            | Unique ECS Task Definition Name                                                 | Yes       |
| `ecs_task_execution_role`             | Name of the IAM role that allows Fargate to publish logs to CloudWatch and to download Prowler image from Amazon ECR.                                                                                                               | Yes       |
| `fargate_task_cpu`                    | CPU Reservation for ECS Fargate Task                                            | Yes       |
| `fargate_memory`                      | Memory Reservation for ECS Fargate Task                                         | Yes       |
| `ecr_image_uri`                       | URI Path of the Prowler Docker Image - Preferably from ECR                      | Yes       |
| `container_name`                      | Name of the Container within ECS Fargate                                        | Yes       |
| `cwe_log_prefix`                      | Prefix for CloudWatch Event Log Group                                           | Yes       |
| `prowler_schedule_task_expression`    | Schedule Expression to run the Prowler ECS Fargate Task                         | Yes       |
| `prowler_scheduled_task_event_role`   | Name of the IAM Role for the CloudWatch Event Task Scheduler for ECS Fargate    | Yes       |
| `fargate_platform_version`            | FARGATE Platform Version                                                        | Yes       |
| `prowler_container_sg_id`             | Provide a Security Group ID to launch Prowler container                         | Yes       |
| `prowler_container_vpc_subnet_id`     | Provide a Subnet ID to launch Prowler container                                 | Yes       |
| `log_retention_in_days`               | Number of days container task logs will be retained in CloudWatch               | Yes       |
| `assign_container_public_ip`          | Assign public IP to the container                                               | Yes       |
| `tags`                                | A map of tags (key-value pairs) passed to resources.                            | Yes       |


## Outputs

All output details can be found in [aws-tf-prowler-fargate/outputs.tf](outputs.tf).

| Output Name                 | Description                                |
| -------------               | -----------                                |
| `aws_ecs_cluster_arn`       | ARN of the ECS Fargate Cluster             |
| `aws_ecs_task_definition`   | ARN of the ECS Task Definition"            |
| `aws_s3_bucket`             | ARN of the S3 Bucket                       |
| `aws_iam_role`              | ARN of the Prowler role                    |
| `aws_cloudwatch_log_group`  | ARN of the Amazon CloudWatch Log Group     |