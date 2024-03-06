# [UNiXIaC](https://github.com/UNiXMIT/UNiXIaC)
- [Prerequisites](#prerequisites)
- [Minimum AWS EC2 Instance requirements](#minimum-aws-ec2-instance-requirements)
- [Install Instructions](#install-instructions)
- [Ansible Semaphore](#ansible-semaphore)
- [Update Semaphore/NGiNX](#update-semaphorenginx)
- [Generate SSH Key](#generate-ssh-key)
- [Update TLS Certificate/Key](#update-tls-certificatekey)
- [Backup Semaphore](#backup-semaphore)
- [Check Semaphore Logs](#check-semaphore-logs)
- [Tags](#tags)
  - [Windows](#windows)
  - [Linux](#linux)  

## Prerequisites
Install Podman (or Docker).  
```
dnf install podman -y
```
## Cloud Environment
### Minimum AWS EC2 Instance requirements
t3.micro  
20GB SSD  

### Minimum Azure EC2 Instance requirements
Standard_B2ls_v2  
20GB SSD  

## Install/Update Instructions
```
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/semaphore.sh
chmod +x semaphore.sh
mkdir /home/support/semaphore/config
mkdir /home/support/semaphore/db
semaphore.sh
```
**NOTE:** Dockerfile, pfsso*.zip and support.pem must be located in the current working directory before starting the build. 

## Ansible Semaphore
#### https://www.ansible-semaphore.com
You can access the Semaphore Web UI with:
```
http://serverIP:3000
```

## Backup Semaphore
The Semaphore config and database.boltdb file are mapped onto the host in the following locations:
```
/home/support/semaphore/config/config.json
/home/support/semaphore/db/database.boltdb
```

## Check Semaphore Logs
```
podman logs semaphore
```