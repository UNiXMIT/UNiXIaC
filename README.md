# UNiXIaC
## Install Intructions
```
sudo (apt/yum/zypper) install -y curl podman  
curl -s https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/semaphore.sh | bash  
```
**NOTE:** pfsso*.zip and support.pem must located be in the current working directory before executing semaphore.sh.  

## SSO
Trigger the SSO process using:
```
podman exec -it semaphore bash -c "/root/sso.sh"
```
Credentials will last for 1 hour.  

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
- vs2022
  - edvs2022_80
- ede80
- extend1050

##### RHEL9
- default
- destroy