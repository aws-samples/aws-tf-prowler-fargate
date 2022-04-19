output "ecs_cluster_arn" {
  value       = module.prowler_deployment_account.aws_ecs_cluster_arn
  description = "ARN of the AWS Fargate Cluster"
}

output "ecs_task_definition" {
  value       = module.prowler_deployment_account.aws_ecs_task_definition
  description = "ARN of the ECS Task Definition"
}

output "s3_bucket" {
  value       = module.prowler_deployment_account.aws_s3_bucket
  description = "ARN of the S3 Bucket"
}

output "iam_role" {
  value       = module.prowler_deployment_account.aws_iam_role
  description = "ARN of the Prowler role"
}

output "cloudwatch_log_group" {
  value       = module.prowler_deployment_account.aws_cloudwatch_log_group
  description = "ARN of the Amazon CloudWatch Log Group"
}

