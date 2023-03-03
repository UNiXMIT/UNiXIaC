provider "aws" {
  region  = var.instance.awsregion
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
