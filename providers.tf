terraform {
  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #   }
  # }

  backend "s3" {
    bucket = "resmed-terraform-state-bucket"
    key    = "prowler/"
    region = "us-west-2"
  }

}

provider "aws" {
  region  = var.region_primary
  alias   = "prowler_deployment_account"

}

# Prowler Scan Account 1
provider "aws" {
  region = var.region_primary
  alias   = "prowler_account_scan_account_1"
  
  assume_role {
    #role_arn     = "arn:aws:iam::123456789012:role/ROLE_NAME"
    role_arn      = "arn:aws:iam::342057286659:role/Admin"
    session_name = "deploy_prowler_role"
    #external_id  = "EXTERNAL_ID"
  }

}

# Prowler Scan Account 2
provider "aws" {
  region = var.region_primary
  alias   = "prowler_account_scan_account_2"
  
  assume_role {
    #role_arn     = "arn:aws:iam::123456789012:role/ROLE_NAME"
    role_arn      = "arn:aws:iam::605706657514:role/Admin"
    session_name = "deploy_prowler_role"
    #external_id  = "EXTERNAL_ID"
  }

}