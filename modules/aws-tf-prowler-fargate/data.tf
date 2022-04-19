data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_organizations_organization" "org" {}

data "aws_iam_policy" "AWS_Managed_ECS_Events_Role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

data "aws_iam_policy" "AWS_ECS_Task_Execution_Role" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# S3 bucket permissions
data "aws_iam_policy_document" "prowlers3_bucket_policy" {
  statement {
    sid    = "AllowGetPutListObject"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:PutObjectAcl"
    ]

    resources = [
      aws_s3_bucket.prowler_bucket.arn,
      "${aws_s3_bucket.prowler_bucket.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgId"

      values = [data.aws_organizations_organization.org.id]
    }
  }

  statement {
    sid    = "DenyNonSSLRequests"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.prowler_bucket.arn,
      "${aws_s3_bucket.prowler_bucket.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"

      values = [
        "false",
      ]
    }
  }

  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.prowler_bucket.arn}/*",
    ]

    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "false",
      ]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"

      values = [
        "AES256",
      ]
    }
  }
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
      aws_s3_bucket.prowler_bucket.arn,
      "${aws_s3_bucket.prowler_bucket.arn}/*",
    ]
  }

  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    resources = [ "arn:aws:iam::*:role/${var.prowler_iamrole_name}" ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgId"

      values = [data.aws_organizations_organization.org.id]
    }
  }

}



