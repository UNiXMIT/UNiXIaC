resource "aws_instance" "aws" {
  ami               = var.awsAMI
  instance_type     = var.InstanceType
  availability_zone = var.availZone
  security_groups   = [var.securityGroup]
  key_name          = var.sshKeyName

  root_block_device {
    volume_size = var.diskSize
    volume_type = var.volumeType
  }

  tags = {
    Name    = "${var.corpID}-RHEL9"
    OS      = "RHEL9"
    Created = "${formatdate("YYYYMMDDhhmmss", timestamp())}"
    Owner   = var.corpID
  }
}