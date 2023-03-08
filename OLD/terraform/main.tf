# Set cloud provider and default region
provider "aws" {
    profile = var.securityProfile
    region = var.region
}