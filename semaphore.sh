#!/bin/bash
# Install Intructions
# sudo (apt/yum/zypper) install -y curl podman
# curl -s https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/semaphore.sh | bash
podman pull rockylinux:9
podman run -itd --name semaphore -p 8181:3000 rockylinux:9
podman exec -it semaphore bash -c "dnf epel-release -y"
podman exec -it semaphore bash -c "dnf install ansible wget git python3 python3-pip tmux unzip -y"
podman exec -it semaphore bash -c "python3 -m pip install boto3"
podman exec -it semaphore bash -c "wget -P /root https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.75/semaphore_2.8.77_linux_amd64.rpm"
podman exec -it semaphore bash -c "dnf install semaphore*.rpm"
podman exec -it semaphore bash -c "cd /root && semaphore setup"
podman exec -it semaphore bash -c "cd /root && tmux new -d -s semaphore semaphore server --config /root/config.json"
podman cp pfsso*.zip semaphore:/root
podman cp support.pem semaphore:/root/.ssh
podman exec -it semaphore bash -c "chmod 600 /root/.ssh/support.pem"
podman exec -it semaphore bash -c "cd /root && unzip pfsso*.zip"
podman exec -it semaphore bash -c "python3 -m pip install --upgrade /root/pfsso*/"
podman exec -it semaphore bash -c "wget -P /root https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/sso.sh"
podman exec -it semaphore bash -c "chmod +x /root/sso.sh"