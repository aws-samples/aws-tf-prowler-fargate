output "aws_ecs_cluster_arn" {
  description = "ARN of the ECS Fargate Cluster"
  value       = aws_ecs_cluster.prowler_ecs_cluster.arn
}

output "aws_ecs_task_definition_1" {
  description = "ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.prowler_ecs_task_definition_1.arn
}

output "aws_ecs_task_definition_2" {
  description = "ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.prowler_ecs_task_definition_2.arn
}

output "aws_s3_bucket" {
  description = "ARN of the S3 Bucket"
  value       = aws_s3_bucket.prowler_bucket.arn
}

output "aws_iam_role" {
  description = "ARN of the Prowler role"
  value       = aws_iam_role.prowler_role.arn
}

output "aws_cloudwatch_log_group_1" {
  description = "ARN of the Amazon CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.prowler_cw_log_group_1.arn
}

output "aws_cloudwatch_log_group_2" {
  description = "ARN of the Amazon CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.prowler_cw_log_group_2.arn
}

