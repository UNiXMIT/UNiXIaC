locals {
  vmname = "${var.corpid}-${var.wins2022.name}"
}

resource "aws_instance" "computer" {
  ami               = var.wins2022.ami
  instance_type     = var.instance.type
  availability_zone = var.instance.az
  security_groups   = [var.instance.sg]
  key_name          = var.instance.ssh_key_name
  user_data         = file("userData.txt")

  root_block_device {
    volume_size = var.instance.root_disk_size
    volume_type = var.instance.volume_type
  }

  tags = {
    Name    = local.vmname
    prod0   = "Windows Server 2022"
    Created = "${formatdate("YYYYMMDDhhmmss", timestamp())}"
    Owner   = var.instance.owner
  }

# setup hosts file for Ansible
  provisioner "local-exec" {
    command = "echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip}' >hosts"
  }

}

output "wins2022server_ip" {
    value = aws_instance.computer.public_ip
}
