variable "deployment_accountid" {
  type        = string
  description = "The AWS Account Id to deploy Prowler"
}

variable "prowler_iamrole_name" {
  type        = string
  description = " IAM role name to assign to prowler cross-account role"
  default     = "prowler-sec-assessment-role"
}

variable "prowler_s3" {
  type        = string
  description = "Enter S3 Bucket for Prowler Reports.  prefix-awsaccount-awsregion"
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default = {
    Application = "prowler-security-assessment"
    Deployment  = "Terraform"
  }
}