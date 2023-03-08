variable "corpID" {
  type = string
  description = "CORPID for AWS tags"
}

variable "region" {
  type        = string
  default     = "us-west-2"
  description = "The region to create the infrastructure"
}

variable "privateKeyName" {
  type        = string
  description = "The private key to be used in order to SSH to EC2 instances"
}

variable "awsAMI" {
  type        = string 
  description = "The id of the machine image (AMI) to use for the server."
}

variable "InstanceType" {
  type        = string
  default     = "t3.xlarge"
  description = "The EC2 instance type"
}

variable "username" {
  type = string
  description = "User to create in new instance"
}

variable "password" {
  type = string
  sensitive   = true
}

variable "volumeType" {
  type = string
  default = "gp3"
  description = "Volume Type"
}

variable "diskSize" {
  type = string
  default = "120"
  description = "Root disk size"
} 

variable "availZone" {
  type = string
  description = "Availability Zone"
}

variable "securityGroup" {
  type = "string"
  description = "Security Group"
}

variable "securityProfile" {
  type = "string"
  description = "Security Profile"
}

variable "sshUser" {
  type = "string"
  default = "ec2-user"
  description = "SSH User"
}

variable "privateKeyFile" {
  type = "string"
  default = "~/.ssh/support.pem"
  description = "Security Group"
}

variable "sshKeyName" {
  type        = string
  description = "SSH Key Name"
}
