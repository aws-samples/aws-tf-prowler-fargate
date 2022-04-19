data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_organizations_organization" "org" {}

data "aws_iam_policy" "AWS_Managed_ECS_Events_Role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

data "aws_iam_policy" "AWS_ECS_Task_Execution_Role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Prowler Cross Account IAM Role
data "aws_iam_policy_document" "crossaccount_assume_policy" {

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.deployment_accountid}:root"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"

      values = ["arn:aws:iam::${var.deployment_accountid}:role/${var.prowler_iamrole_name}"]
    }
  }
}

data "aws_iam_policy_document" "crossaccount_policy" {
  statement {
    sid = "AllowMoreReadForProwler"
    actions = [
      "access-analyzer:List*",
      "apigateway:Get*",
      "apigatewayv2:Get*",
      "aws-marketplace:ViewSubscriptions",
      "dax:ListTables",
      "ds:ListAuthorizedApplications",
      "ds:DescribeRoles",
      "ec2:GetEbsEncryptionByDefault",
      "ecr:Describe*",
      "lambda:GetAccountSettings",
      "lambda:GetFunctionConfiguration",
      "lambda:GetLayerVersionPolicy",
      "lambda:GetPolicy",
      "opsworks-cm:Describe*",
      "opsworks:Describe*",
      "secretsmanager:ListSecretVersionIds",
      "sns:List*",
      "sqs:ListQueueTags",
      "states:ListActivities",
      "support:Describe*",
      "tag:GetTagKeys",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "elasticfilesystem:DescribeBackupPolicy",
    ]

    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "AllowGetPutListObject"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]

    effect = "Allow"
    resources = [
      "arn:aws:s3:::${var.prowler_s3}",
      "arn:aws:s3:::${var.prowler_s3}/*"
    ]
  }
}



