provider "aws" {
  profile = var.instance.securityprofile
  region  = var.instance.awsregion
  shared_credentials_files = ["/root/.aws/credentials"]
  shared_config_files = ["/root/.aws/config"]
}

terraform {
  required_providers {
    aws = {
      version = "~> 4.57.0"
      source = "hashicorp/aws"
    }
    external = {
      version = "~> 2.0.0"
      source = "hashicorp/external"
    }
  }
}
