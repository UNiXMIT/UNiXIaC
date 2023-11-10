# UNiXIaC
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
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/Dockerfile
curl -s -O https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/semaphore.sh
chmod +x semaphore.sh
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

## Tags
### Windows

- default
- vs2019
  - ed
    - ed50
    - ed60
    - ed70
      - edpu
        - ed70pu15
        - ed70pu16
        - ed70pu17
        - ed70pu18
        - ed70pu19
        - ed70pu20
        - ed70pu21
- vs2022
  - ed 
    - ed80
      - edpu
        - ed80pu5
        - ed80pu6
        - ed80pu7
        - ed80pu8
        - ed80pu9
        - ed80pu10
        - ed80pu11
    - ed90
      - edpu
        - ed90pu1
        - ed90pu2
        - ed90pu3
- extend
  - extend1040
  - extend1041
  - extend1050
  - extend1050pu1

### Linux
##### RHEL
- default
- ed
  - ed50
  - ed60
  - ed70pu15
  - ed70pu16
  - ed70pu17
  - ed70pu18
  - ed70pu19
  - ed70pu20
  - ed70pu21
  - ed80pu5
  - ed80pu6
  - ed80pu7
  - ed80pu8
  - ed80pu9
  - ed80pu10
  - ed80pu11
  - ed90
  - ed90pu1
  - ed90pu2
  - ed90pu3
- extend
  - extend1040
  - extend1041
  - extend1050
  - extend1050pu1