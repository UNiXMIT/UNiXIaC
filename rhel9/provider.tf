provider "aws" {
  profile = var.instance.securityprofile
  region  = var.instance.awsregion
}

terraform {
  required_providers {
    aws = {
      version = "~> 3.15.0"
      source = "hashicorp/aws"
    }
    external = {
      version = "~> 2.0.0"
      source = "hashicorp/external"
    }
  }
}
