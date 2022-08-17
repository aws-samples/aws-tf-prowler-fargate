terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      #version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket = "example-terraform-state-bucket"
    key    = "security_account/prowler/"
    region = "us-west-2"
  }
}


provider "aws" {
  version = "~> 4.9.0"
  region  = "var.region_primary"
  alias   = "prowler_deployment_account"
}

provider "aws" {
  version = "~> 4.9.0"
  region  = "var.region_primary"
  alias   = "prowler_account_to_scan"
}