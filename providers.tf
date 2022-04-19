provider "aws" {
  version = "~> 4.9.0"
  region  = "var.region_primary"
  alias   = "prowler_deployment_account"
}
