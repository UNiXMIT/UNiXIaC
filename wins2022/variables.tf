variable "corpid" {
  type = string
  default = "MTURNER"
}

variable "image" {
  default = {
    ami = "ami-01e91a8e71e619d87"
    name = "WINS2022"
  }
}

variable "username" {
  default = "support"
}

variable "password" {
  type = string
  default = "Unidos30"
  sensitive   = true
}

variable "instance" {
  description = "instance parameters"
  type        = map(string)
  default = {
    securuityprofile = "848105473048_Fed_COBOL2_Compute"
    awsregion        = "eu-west-2"
    type             = "t3.xlarge"
    root_disk_size   = "120"
    volume_type      = "gp3"
    az               = "eu-west-2c"
    sg               = "MTURNER"
    ssh_user         = "ec2-user"
    ssh_key_name     = "support"
    pemfile          = "~/.ssh/support.pem"
    owner            = "martin.turner@microfocus.com"
  }
}