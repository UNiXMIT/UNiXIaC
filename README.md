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

### Ansible   
```
sudo dnf install ansible -y  
python3 -m pip install boto3  
```

### Support PEM 
``` 
sudo chmod 600 ~/.ssh/support.pem  
```

### Scripts Executable 
```
sudo chmod +x *.sh
```

## Instances
- Linux
  - RHEL 9