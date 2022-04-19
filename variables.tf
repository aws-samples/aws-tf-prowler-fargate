variable "deployment_accountid" {
  type        = string
  description = "The AWS Account Id to deploy Prowler"
}

variable "ecr_image_uri" {
  type        = string
  description = "URI Path of the Prowler Docker Image - Preferably from ECR"
}

variable "region_primary" {
  type        = string
  description = "AWS Region to deploy to"
}

# variable "prowler_schedule_task_expression" {
#   type        = string
#   default     = "rate(7 days)"
#   description = "Schedule Expression to run the Prowler AWS Fargate Task"
# }

variable "prowler_container_sg_id" {
  type        = string
  description = "Provide a Security Group ID to launch Prowler container"
}
variable "prowler_container_vpc_subnet_id" {
  type        = string
  description = "Provide a Subnet ID to launch Prowler container"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default = {
    Application = "prowler-security-assessment"
    Deployment  = "Terraform"
  }
}
