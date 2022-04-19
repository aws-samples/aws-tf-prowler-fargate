# `aws-tf-prowler-fargate/aws-tf-iam-role`


## Description

This Terraform module implements an [AWS Identity and Access Management](https://aws.amazon.com/iam/) role that helps you assess your multi-account environment in [AWS Organizations](https://aws.amazon.com/organizations/) using [Prowler](https://github.com/toniblyx/prowler) security assessment tool  deployed on [AWS Fargate](https://aws.amazon.com/fargate/). The role is assumed by the Prowler deployment account and should be deployed to your management account and the member accounts you want to include in the assessment scope.

## Module Components
1.  [main.tf](./main.tf)
    * Creates an IAM role assumed by Prowler deployment account.
    * Allows Prowler to write assessment report to a central S3 bucket.

2.  [outputs.tf](./outputs.tf)
    * Defines the [Terraform output](https://www.terraform.io/docs/language/values/outputs.html) values of this Terraform module.

4.  [variables.tf](./variables.tf)
    * Defines the input variables for this Terraform module.

6. [data.tf](./data.tf)
    * Defines the IAM policy document for the Prowler role.

## Resources

| Name                            | Type         |
| ---------                       |----          |
| aws_iam_role                    | Resource     |
| aws_iam_policy                  | Resource     |
| aws_iam_policy_attachment       | Resource     |


## Input Variables

All variable details can be found in [aws-tf-prowler-fargate/aws-tf-iam-role](aws-tf-iam-role.tf). Refer to the file for default variable values.

| Variable Name               | Description                                                                     | Required  |
| -------------               | -----------                                                                     | --------  |
| `deployment_accountid`      | The AWS Account Id to deploy Prowler                                            | Yes       |
| `prowler_iamrole_name`      | IAM role name to assign to prowler cross-account role                           | Yes       |
| `prowler_s3`                | Enter the S3 Bucket for Prowler Reports. Format: prefix-awsaccount-awsregion    | Yes       |
| `tags`                      | A map of tags (key-value pairs) passed to resources.                            | Yes       |


## Outputs

All output details can be found in [aws-tf-prowler-fargate/outputs.tf](outputs.tf).

| Output Name                 | Description                                |
| -------------               | -----------                                |
| `aws_iam_role`              | ARN of the Prowler IAM role                |