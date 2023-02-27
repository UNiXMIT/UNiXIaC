locals {
  vmname = "${var.corpid}-${var.rhel9.name}"
}

data "cloudinit_config" "server_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloudConfig.yml", {
      header: var.instance.sg
    })
  }
}

resource "aws_instance" "computer" {
  ami               = var.rhel9.ami
  instance_type     = var.instance.type
  availability_zone = var.instance.az
  security_groups   = [var.instance.sg]
  key_name          = var.instance.ssh_key_name
  user_data         = data.cloudinit_config.server_config.rendered

  root_block_device {
    volume_size = var.instance.root_disk_size
    volume_type = var.instance.volume_type
  }

  tags = {
    Name    = local.vmname
    prod0   = "RHEL 9"
    Created = "${formatdate("YYYYMMDDhhmmss", timestamp())}"
    Owner   = var.instance.owner
  }

# setup hosts file for Ansible
  provisioner "local-exec" {
    command = "echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip}' >hosts"
  }

}

output "rhel9server_ip" {
    value = aws_instance.computer.public_ip
}
