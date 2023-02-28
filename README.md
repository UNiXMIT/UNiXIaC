# UNiXIaC

- [Prerequisites](#prerequisites)
- [Instances](#instances)

## Prerequisites
### Python3 and pip
```
sudo dnf install python3 python3-pip -y  
```
### PFSSO 
```
python3 -m pip install --upgrade .
```
https://github.houston.softwaregrp.net/HPE-SW-SaaS/pfsso-python  
### Terraform 
```
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```
https://developer.hashicorp.com/terraform/downloads  
### Ansible   
```
sudo dnf install ansible sshpass -y
```
### Support PEM 
support.pem located in ~/.ssh 
sudo chmod 600 ~/.ssh/support.pem
### Scripts Executable 
```
sudo find . -name "*.sh" -exec chmod +x {} \; 
```

## Instances
- Linux
  - RHEL 9
- Windows
  - Windows Server 2022