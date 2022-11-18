output "ecs_cluster_arn" {
  value       = module.prowler_ecs_instance_deployment.aws_ecs_cluster_arn
  description = "ARN of the AWS Fargate Cluster"
}

output "ecs_task_definition_1" {
  value       = module.prowler_ecs_instance_deployment.aws_ecs_task_definition_1
  description = "ARN of the ECS Task Definition"
}

output "ecs_task_definition_2" {
  value       = module.prowler_ecs_instance_deployment.aws_ecs_task_definition_2
  description = "ARN of the ECS Task Definition"
}

output "s3_bucket" {
  value       = module.prowler_ecs_instance_deployment.aws_s3_bucket
  description = "ARN of the S3 Bucket"
}

output "iam_role" {
  value       = module.prowler_ecs_instance_deployment.aws_iam_role
  description = "ARN of the Prowler role"
}

output "cloudwatch_log_group_1" {
  value       = module.prowler_ecs_instance_deployment.aws_cloudwatch_log_group_1
  description = "ARN of the Amazon CloudWatch Log Group"
}


output "cloudwatch_log_group_2" {
  value       = module.prowler_ecs_instance_deployment.aws_cloudwatch_log_group_2
  description = "ARN of the Amazon CloudWatch Log Group"
}
