#!/bin/bash
# Install Intructions
# sudo dnf install -y curl podman
# curl -s https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/semaphore.sh | bash
if [ $1="podman" ] 
then
    podman pull rockylinux:9
    podman run -itd --name semaphore -p 8181:3000 rockylinux:9
    podman exec -it semaphore bash -c "dnf install epel-release -y"
    podman exec -it semaphore bash -c "dnf install ansible wget git python3 python3-pip tmux unzip python-winrm -y"
    podman exec -it semaphore bash -c "ansible-galaxy collection install amazon.aws"
    podman exec -it semaphore bash -c "python3 -m pip install boto3 pexpect pypsrp pywinrm"
    podman exec -it semaphore bash -c "wget -P /root https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.90/semaphore_2.8.90_linux_amd64.rpm"
    podman exec -it semaphore bash -c "dnf install /root/semaphore*.rpm -y"
    podman exec -it semaphore bash -c "cd /root && semaphore setup"
    podman exec -it semaphore bash -c "cd /root && tmux new -d -s semaphore semaphore server --config /root/config.json"
    podman cp pfsso*.zip semaphore:/root
    podman cp support.pem semaphore:/root/.ssh
    podman exec -it semaphore bash -c "chmod 600 /root/.ssh/support.pem"
    podman exec -it semaphore bash -c "cd /root && unzip pfsso*.zip"
    podman exec -it semaphore bash -c "python3 -m pip install --upgrade /root/pfsso*/"
else
    dnf install epel-release -y
    dnf install ansible wget git python3 python3-pip tmux unzip python-winrm -y
    ansible-galaxy collection install amazon.aws
    python3 -m pip install boto3 pexpect pypsrp pywinrm
    wget https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.90/semaphore_2.8.90_linux_amd64.rpm
    dnf install /root/semaphore*.rpm -y
    semaphore setup
    tmux new -d -s semaphore semaphore server --config config.json
    cp support.pem ~/.ssh/support.pem
    chmod 600 ~/.ssh/support.pem
    unzip pfsso*.zip
    python3 -m pip install --upgrade ${PWD}/pfsso*/
fi