# UNiXIaC
## Install Intructions
```
sudo (apt/yum/zypper) install -y curl podman  
curl -s https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/semaphore.sh | bash  
```
**NOTE:** pfsso*.zip and support.pem must be located in the current working directory before executing semaphore.sh.  

## SSO
Trigger the SSO process using the alias:
```
sso
```
Credentials will last for 1 hour.  

## Products
Product installers should be copied into the /products directory of the container i.e.  
```
podman cp installer.exe containerName:/products
```

## Ansible Semaphore - https://www.ansible-semaphore.com
You can access the Semaphore Web UI with:
```
http://ServerIP:8181  
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
- ede70
  - ede70pu15
- ede80
- es70
  - es70pu15
- es80
- extend1050

### Linux
##### RHEL9
- default
- destroy
- es80
- extend1050