# [UNiXIaC](https://github.com/UNiXMIT/UNiXIaC)
- [Prerequisites](#prerequisites)
- [Minimum AWS EC2 Instance requirements](#minimum-aws-ec2-instance-requirements)
- [Install Instructions](#install-instructions)
- [Ansible Semaphore](#ansible-semaphore)
- [Update Semaphore/NGiNX](#update-semaphorenginx)
- [Backup Semaphore](#backup-semaphore)
- [Check Semaphore Logs](#check-semaphore-logs)

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
mkdir -p semaphore/config
semaphore.sh
```
**NOTE:** The support.pem must be located in the semaphore directory before starting the build. If you have a config.json, place it in the semaphore/config directory.  

## Command Line  
### Create admin user
```
podman exec it semaphore semaphore user add --admin --login john --name=John --email=john1996@gmail.com --password=12345 --config=/etc/semaphore/config.json  
```

## Ansible Semaphore
#### https://www.ansible-semaphore.com
You can access the Semaphore Web UI with:
```
http://serverIP:3000
```

## Check Semaphore Logs
```
podman logs semaphore
```