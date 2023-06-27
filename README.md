# UNiXIaC
- [Prerequisites](#prerequisites)
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

## Install Instructions
```

./run.sh
```
**NOTE:** pfsso*.zip, support.pem, semaphore.service, entrypoint.sh, semaphoreBasic.conf,  config.json and database.boltdb must be located in the current working directory before executing build.sh  
**NOTE2:** If enabling TLS, un-comment the 3 COPY lines in the Dockerfile and comment out the COPY on line 28. Make sure that semaphoreTLS.conf, cert.pem amd key.pem are located in the current working directory before executing build.sh  

## Ansible Semaphore
#### https://www.ansible-semaphore.com
You can access the non-TSL Semaphore Web UI with:
```
http://serverIP:8080
```
and TLS enabled Semaphore Web UI with:
```
https://serverHostname:8081
```

## Update Semaphore/NGiNX
```
podman exec -it -u 0 SEMAPHORE rm -rf /root/semaphore.rpm
podman exec -it -u 0 SEMAPHORE wget -O /root/semaphore.rpm https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.90/semaphore_2.8.90_linux_amd64.rpm
podman exec -it -u 0 SEMAPHORE dnf install /root/semaphore.rpm -y
```
```
podman exec -it -u 0 SEMAPHORE dnf update nginx
```

## Update TLS Certificate/Key
Generate the new cert/key and place them in the current directory before executing the following commands:  
```
podman cp cert.pem SEMAPHORE:/etc/nginx/certs/cert.pem
podman cp cert.pem SEMAPHORE:/etc/nginx/certs/key.pem
podman exec -it -u 0 SEMAPHORE /usr/bin/systemctl reload nginx
```

## Backup Semaphore
```
podman cp SEMAPHORE:/root/config.json /home/support/config.json
podman cp SEMAPHORE:/root/database.boltdb /home/support/database.boltdb
```

## Check Semaphore Logs
```
podman logs SEMAPHORE
```

## Tags
### Windows

- default
- vs2019
  - ed
    - ed70
      - edpu
        - ed70pu15
        - ed70pu16
        - ed70pu17
        - ed70pu18
        - ed70pu19
- vs2022
  - ed 
    - ed80
      - edpu
        - ed80pu5
        - ed80pu6
        - ed80pu7
    - ed90
- extend
  - extend1050
  - extend1050pu1

### Linux
##### RHEL
- default
- rhel<=8
- rhel>=9
- ed
  - ed70pu15
  - ed70pu16
  - ed70pu17
  - ed70pu18
  - ed70pu19
  - ed80pu5
  - ed80pu6
  - ed80pu7
  - ed90
- extend
  - extend1050
  - extend1050pu1