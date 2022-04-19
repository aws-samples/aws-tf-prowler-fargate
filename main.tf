module "prowler_deployment_account" {
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
