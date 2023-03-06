provider "aws" {
  profile = var.instance.securityprofile
  region  = var.instance.awsregion
  shared_credentials_file = "~/.aws/credentials"
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
