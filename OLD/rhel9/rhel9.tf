locals {
  vmname = "${var.corpid}-${var.image.name}"
}

resource "aws_instance" "computer" {
  ami               = var.image.ami
  instance_type     = var.instance.type
  availability_zone = var.instance.az
  security_groups   = [var.instance.sg]
  key_name          = var.instance.ssh_key_name

  root_block_device {
    volume_size = var.instance.root_disk_size
    volume_type = var.instance.volume_type
  }

  tags = {
    Name    = local.vmname
    prod0   = var.image.name
    Created = "${formatdate("YYYYMMDDhhmmss", timestamp())}"
    Owner   = var.corpid
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -E \"s/#?AllowTcpForwarding no/AllowTcpForwarding yes/\" /etc/ssh/sshd_config",
      "sudo sed -i -E \"s/#?PasswordAuthentication no/PasswordAuthentication yes/\" /etc/ssh/sshd_config",
      "sudo bash -c 'echo \"%wheel ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'"
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.computer.public_ip
      user        = var.instance.ssh_user
      private_key = file(var.instance.pemfile)
    }
  }

# Ansible Playbooks
  provisioner "local-exec" {
    command = <<-EOT
              echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip} ansible_port=22 ansible_user=${var.instance.ssh_user} ansible_ssh_private_key_file=${var.instance.pemfile}' > hostsMain
              echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip} ansible_port=22 ansible_user=${var.username} ansible_password=${var.password}' > hostsSupport
              ansible-playbook -i hostsMain knownHosts.yml
    EOT
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i hostsMain system.yml"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i hostsMain users.yml -e \"myUsername=${var.username} myPassword=${var.password}\""
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i hostsMain software.yml"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i hostsSupport createFilesDir.yml -e \"myUsername=${var.username}\""
  }

  provisioner "local-exec" {
    command = <<-EOT
              ansible-playbook -i hostsMain motd.yml
              ansible-playbook -i hostsMain cron.yml -e "myUsername=${var.username}"
    EOT
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i hostsMain reboot.yml"
  }

}

output "server_ip" {
    value = aws_instance.computer.public_ip
}
