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
    Owner   = var.instance.owner
  }

  # Setup Ansible for Windows Host
  user_data = <<-EOF
      <powershell>
      C:\\ProgramData\\Amazon\\EC2-Windows\\Launch\\Scripts\\InitializeInstance.ps1 -Schedule
      
      # Enable Ansible
      $urla = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
      Invoke-Expression ((New-Object System.Net.Webclient).DownloadString($urla))
      
      # Create user and add them to Administrators and Remote Desktop Users groups
      New-LocalUser ${var.username} -Password (ConvertTo-SecureString -AsPlainText ${var.password} -Force) -FullName ${var.username}
      Add-LocalGroupMember -Group "Administrators" -Member ${var.username} -ErrorAction stop
      Add-LocalGroupMember -Group "Remote Desktop Users" -Member ${var.username} -ErrorAction stop

      # The following steps are outlined in the Ansible documentation.
      # https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html

      # Upgrade PowerShell & .NET framework
      $urlps = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Upgrade-PowerShell.ps1"
      $fileps = "$env:temp\Upgrade-PowerShell.ps1"
      (New-Object -TypeName System.Net.WebClient).DownloadFile($urlps, $fileps)
      Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
      # Version can be 3.0, 4.0 or 5.1
      &$fileps -Version 5.1 -Username ${var.username} -Password (ConvertTo-SecureString -AsPlainText ${var.password} -Force)

      # Remove auto-logon and set the execution policy back to the default
      # ('Restricted' for Windows clients, or 'RemoteSigned' for Windows servers)
      # This isn't needed but is a good security practice to complete
      #Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force ### !!! TRACE THIS !!! ###
      $reg_winlogon_path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
      Set-ItemProperty -Path $reg_winlogon_path -Name AutoAdminLogon -Value 0
      Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultUserName -ErrorAction SilentlyContinue
      Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultPassword -ErrorAction SilentlyContinue

      ## Configure WinRM service so Ansible can connect
      # Setup WinRM Listener
      winrm quickconfig -transport:https

      ## Install OpenSSH
      # (REVISIT: This should dynamically find latest version)
      Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -LogLevel WarningsInfo > C:\test6\log.txt 2>&1
      #Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

      # Configure OpenSSH
      Start-Service sshd
      Set-Service -Name sshd -StartupType 'Automatic'
      # Confirm the Firewall rule is configured. It should be created automatically by setup. Run the following to verify
      if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
          Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
          New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
      } else {
          Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
      }

      </powershell>
  EOF

  provisioner "local-exec" {
    command = <<-EOT
              echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip} ansible_port=22 ansible_user=${var.instance.ssh_user} ansible_ssh_private_key_file=${var.instance.pemfile}' > hostsMain
              echo '${local.vmname} ansible_host=${aws_instance.computer.public_ip} ansible_port=22 ansible_user=${var.username} ansible_password=${var.password}' > hostsSupport
    EOT
  }

}

output "server_ip" {
    value = aws_instance.computer.public_ip
}
