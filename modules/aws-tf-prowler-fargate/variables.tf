variable "deployment_accountid" {
  type        = string
  description = "The AWS Account Id to deploy Prowler"
}

variable "prowler_iamrole_name" {
  type        = string
  description = " IAM role name to assign to prowler cross-account role"
  default     = "prowler-sec-assessment-role"
}

variable "ecs_cluster_name" {
  type        = string
  default     = "prowler-security-assessment-cluster"
  description = "AWS Fargate Cluster Name"
}
variable "ecs_task_definition_name" {
  type        = string
  default     = "prowler-security-assessment"
  description = "Unique ECS Task Definition Name"
}
variable "ecs_task_execution_role" {
  type        = string
  description = "Name of the IAM role that allows Fargate to publish logs to CloudWatch and to download Prowler image from Amazon ECR."
  default = "prowler-ecs-task-execution"
}

variable "fargate_task_cpu" {
  type        = string
  default     = "512"
  description = "CPU Reservation for AWS Fargate Task"
}
variable "fargate_memory" {
  type        = string
  default     = "1024"
  description = "Memory Reservation for AWS Fargate Task"
}
variable "ecr_image_uri" {
  type        = string
  description = "URI Path of the Prowler Docker Image - Preferably from ECR"
}
variable "container_name" {
  default     = "prowler-security-assessment-task"
  description = "Name of the Container within AWS Fargate"
}
variable "cwe_log_prefix" {
  type        = string
  default     = "prowlerassessment"
  description = "Prefix for CloudWatch Event Log Group"
}

variable "prowler_scan_type_1" {
  type        = string
  default     = "cislevel2"
  description = "The scan type you want Prowler to perform"
}

variable "prowler_scan_type_2" {
  type        = string
  default     = "extras"
  description = "The scan type you want Prowler to perform"
}

variable "prowler_output_format" {
  type        = string
  default     = "csv"
  description = "The Prowler report output format (csv,html,json)"
}

variable "prowler_schedule_task_expression" {
  type        = string
  default     = "rate(7 days)"
  description = "Schedule Expression to run the Prowler AWS Fargate Task"
}
variable "prowler_scheduled_task_event_role" {
  default     = "aws-prowler-cwe-role"
  description = "Name of the IAM Role for the CloudWatch Event Task Scheduler for AWS Fargate"
}
variable "fargate_platform_version" {
  default     = "1.4.0"
  description = "FARGATE Platform Version"
}
variable "prowler_container_sg_id" {
  type        = string
  description = "Provide a Security Group ID to launch Prowler container"
}
variable "prowler_container_vpc_subnet_id" {
  type        = string
  description = "Provide a Subnet ID to launch Prowler container"
}
variable "log_retention_in_days" {
  description = "Number of days container task logs will be retained in CloudWatch."
  default     = 30
  type        = number
}
variable "assign_container_public_ip" {
  description = "Assign public IP to the container."
  default     = true
  type        = bool
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default = {
    Application = "prowler-security-assessment"
    Deployment  = "Terraform"
  }
}