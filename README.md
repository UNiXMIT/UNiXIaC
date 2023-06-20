# UNiXIaC
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

## Ansible Semaphore - https://www.ansible-semaphore.com
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

## Generate SSH Key for GitHub authentication
Execute the following command, substituting in your GitHub email address.  
```
ssh-keygen -t ed25519 -C "your_email@example.com"
```
This creates a new SSH key, using the provided email as a label.  

> Generating public/private ALGORITHM key pair.  

When you're prompted to "Enter a file in which to save the key", you can press Enter to accept the default file location. Please note that if you created SSH keys previously, ssh-keygen may ask you to rewrite another key, in which case we recommend creating a custom-named SSH key. To do so, type the default file location and replace id_ssh_keyname with your custom key name.  

> Enter a file in which to save the key (/home/YOU/.ssh/ALGORITHM):[Press enter]

Ensure the ssh-agent is running.  
```
eval "$(ssh-agent -s)"
```

Add your SSH private key to the ssh-agent.  
```
ssh-add ~/.ssh/id_ed25519
```

Add the SSH public key to your account on GitHub  - https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account  

**SOURCE:** https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux  

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
- vs2022
  - ed 
    - ed80
      - edpu
        - ed80pu5
        - ed80pu6
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
  - ed80pu5
  - ed80pu6
  - ed90
- extend
  - extend1050
  - extend1050pu1