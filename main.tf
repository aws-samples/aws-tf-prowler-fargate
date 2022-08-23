## Call Module to Deploy the Prowler ECS Instance and Role
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


#Call Module to Deploy the Prowler Cross-Account Role
module "prowler_iam_cross_account_role_1" {
  source = "./modules/aws-tf-iam-role"
  providers = {
    aws = aws.prowler_account_scan_account_1
  }
  
  # The AWS account id for the account that will run Prowler.
  deployment_accountid = var.deployment_accountid
  prowler_s3 = "prowler-111111111111-us-west-2"

}

module "prowler_iam_cross_account_role_2" {
  source = "./modules/aws-tf-iam-role"
  providers = {
    aws = aws.prowler_account_scan_account_2
  }
  
  # The AWS account id for the account that will run Prowler.
  deployment_accountid = var.deployment_accountid
  prowler_s3 = "prowler-111111111111-us-west-2"

}