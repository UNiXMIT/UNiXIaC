# UNiXIaC

- [Prerequisites](#prerequisites)
- [Instances](#instances)

## Prerequisites
### Python3 and pip
```
sudo dnf install python3 python3-pip -y  
```
### PFSSO 
https://github.houston.softwaregrp.net/HPE-SW-SaaS/pfsso-python  
### Terraform 
https://developer.hashicorp.com/terraform/downloads  
### Ansible   
```
sudo dnf install ansible -y
```
### Support PEM 
support.pem located in ~/.ssh 
### Scripts Executable 
```
sudo find . -name "*.sh" -exec chmod +x {} \; 
```

## Instances
- Linux
  - RHEL 9
- Windows
  - Windows Server 2022