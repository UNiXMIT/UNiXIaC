# UNiXIaC
## Install Intructions
```
sudo (apt/yum/zypper) install -y curl podman  
curl -s https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/semaphore.sh | bash  
```
**NOTE:** pfsso*.zip and support.pem must be located in the current working directory before executing semaphore.sh.  

## Products
Product installers should be copied into the following directory on the host machine where podman is installed.  

```
/home/semaphore
```

## Ansible Semaphore - https://www.ansible-semaphore.com
You can access the Semaphore Web UI with:
```
http://serverIP:8181  
```

## Tags
### Windows
##### WINS2022
- default
- destroy
- vs2019
  - edvs2019_70
    - edvs2019_70pu15
- vs2022
  - edvs2022_80
  - edvs2022_90
- ede70
  - ede70pu15
- ede80
- ede90
- es70
  - es70pu15
- es80
- es90
- extend1050

### Linux
##### RHEL9
- default
- destroy
- es80
- extend1050