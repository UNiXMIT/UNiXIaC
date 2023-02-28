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

  provisioner "local-exec" {
    command = "echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip} ansible_port=22 ansible_user=support ansible_ssh_private_key_file=~/.ssh/support.pem' >hosts"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -vv -i hosts playbook.yml" 
  }

}

output "wins2022server_ip" {
    value = aws_instance.computer.public_ip
}
