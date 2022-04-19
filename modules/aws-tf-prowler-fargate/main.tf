# Amazon S3 Bucket for Prowler Reports
resource "aws_s3_bucket" "prowler_bucket" {
  bucket = "prowler-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"
  tags = {
    Key   = "App"
    Value = "Prowler"
  }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.prowler_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.prowler_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "server_side_encryption" {
  bucket = aws_s3_bucket.prowler_bucket.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket                  = aws_s3_bucket.prowler_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "prowler_policy" {
  bucket = aws_s3_bucket.prowler_bucket.id
  policy = data.aws_iam_policy_document.prowlers3_bucket_policy.json
}

# Prowler Cross Account IAM Role and Policy - Also used by ECS task
resource "aws_iam_role" "prowler_role" {
  name               = var.prowler_iamrole_name
  description        = "Provides Prowler EC2 instance permissions to assess security of Accounts in AWS Organization"
  assume_role_policy = data.aws_iam_policy_document.crossaccount_assume_policy.json

  tags = {
    Key   = "App"
    Value = "Prowler"
  }
}

resource "aws_iam_policy_attachment" "security_audit" {
  name       = "SecurityAudit"
  roles      = [aws_iam_role.prowler_role.name]
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_policy_attachment" "view_only_access" {
  name       = "ViewOnlyAccess"
  roles      = [aws_iam_role.prowler_role.name]
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}


resource "aws_iam_role_policy" "crossaccount_policy" {
  name       = "ProwlerPolicyAdditions"
  role      = aws_iam_role.prowler_role.id
  policy = data.aws_iam_policy_document.crossaccount_policy.json
}

# Amazon ECS definition
resource "aws_ecs_cluster" "prowler_ecs_cluster" {
  name = var.ecs_cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

resource "aws_ecs_task_definition" "prowler_ecs_task_definition" {
  family                   = var.ecs_task_definition_name
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.prowler_role.arn
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.fargate_task_cpu
  memory                   = var.fargate_memory
  tags = merge(
    var.tags,
    {
      Name = "${var.container_name}-task"
    },
  )
  container_definitions = <<DEFINITION
  [
  {
    "image": "${var.ecr_image_uri}",
    "essential": true,
    "name": "${var.container_name}",
    "networkMode": "awsvpc",
    "logConfiguration": {
      "logDriver": "awslogs",
      "secretOptions": null,
      "options": {
        "awslogs-group": "/ecs/${var.container_name}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "${var.cwe_log_prefix}"
      }
    },
    "environment": [
      {
        "name": "S3BUCKET",
        "value": "${aws_s3_bucket.prowler_bucket.id}"
      },
      {
        "name": "S3ACCOUNT",
        "value": "${data.aws_caller_identity.current.account_id}"
      },
      {
        "name": "ROLE",
        "value": "${aws_iam_role.prowler_role.name}"
      }
    ]
  }
]
  DEFINITION
}

# Amazon CloudWatch configuration
resource "aws_cloudwatch_log_group" "prowler_cw_log_group" {
  name              = "/ecs/${var.container_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_cloudwatch_event_rule" "prowler_task_scheduling_rule" {
  name                = "${var.ecs_task_definition_name}-prowler-task"
  description         = "Run ${var.ecs_task_definition_name} Task at a scheduled time (${var.prowler_schedule_task_expression}) - Managed by Terraform"
  schedule_expression = var.prowler_schedule_task_expression
  tags                = var.tags
}

# IAM role to run CWE scheduler
resource "aws_iam_role" "prowler_scheduled_task_event_role" {
  name               = var.prowler_scheduled_task_event_role
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM role to pull images from ECR
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role
  tags               = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "prowler_scheduled_task_event_role_policy" {
  role       = aws_iam_role.prowler_scheduled_task_event_role.id
  policy_arn = data.aws_iam_policy.AWS_Managed_ECS_Events_Role.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.id
  policy_arn = data.aws_iam_policy.AWS_ECS_Task_Execution_Role.arn
}

# Running ECS tasks on a scheduled basis
resource "aws_cloudwatch_event_target" "Prowler_Scheduled_Scans" {
  rule     = aws_cloudwatch_event_rule.prowler_task_scheduling_rule.name
  arn      = aws_ecs_cluster.prowler_ecs_cluster.arn
  role_arn = aws_iam_role.prowler_scheduled_task_event_role.arn
  ecs_target {
    launch_type         = "FARGATE"
    task_definition_arn = aws_ecs_task_definition.prowler_ecs_task_definition.arn
    task_count          = "1"
    platform_version    = var.fargate_platform_version

    network_configuration {
      security_groups  = [var.prowler_container_sg_id]
      subnets          = [var.prowler_container_vpc_subnet_id]
      assign_public_ip = var.assign_container_public_ip
    }
  }
}