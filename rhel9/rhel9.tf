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

# Setup hosts file for Ansible
  provisioner "local-exec" {
    command = "echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip} ansible_port=22 ansible_user=support ansible_ssh_private_key_file=~/.ssh/support.pem' > hosts"
  }

  provisioner "remote-exec" {
    inline = [
      "echo \"if [[ -t 0 && $- = *i* ]]; then stty -ixon; fi\" >> /home/$user/.bashrc",
      "sudo sed -i -E \"s/#?AllowTcpForwarding no/AllowTcpForwarding yes/\" /etc/ssh/sshd_config",
      "sudo sed -i -E \"s/#?PasswordAuthentication no/PasswordAuthentication yes/\" /etc/ssh/sshd_config",
      "sudo bash -c \"echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\"",
      "sudo service ssh restart",
      "sudo service sshd restart",
      "sudo setenforce 0",
      "sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config" 
    ]
  }

# Ansible Playbooks
  provisioner "local-exec" {
    command = <<-EOT
              ansible-playbook -i hosts users.yml
              ansible-playbook -i hosts software.yml
    EOT
  }

}

output "rhel9server_ip" {
    value = aws_instance.computer.public_ip
}
