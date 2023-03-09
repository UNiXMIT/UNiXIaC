#!/bin/bash
podman pull rockylinux:9
podman run -itd --name semaphore -p 8181:3000 rockylinux:9
podman exec -it semaphore bash -c "mkdir /home/semaphore"
podman exec -it semaphore bash -c "dnf epel-releasey"
podman exec -it semaphore bash -c "dnf install ansible wget git python3 python3-pip tmux unzip -y"
podman exec -it semaphore bash -c "python3 -m pip install boto3"
podman exec -it semaphore bash -c "wget -P /home/semaphore/ https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.75/semaphore_2.8.77_linux_amd64.rpm"
podman exec -it semaphore bash -c "dnf install semaphore_2.8.77_linux_amd64.rpm"
podman exec -it semaphore bash -c "cd /home/semaphore && semaphore setup"
podman exec -it semaphore bash -c "cd /home/semaphore && semaphore service --config=./config.json"
podman exec -it semaphore bash -c "tmux new -d -s semaphore semaphore server --config /home/semaphore/config.json"
podman cp pfsso*.zip semaphore:/home/semaphore
podman cp support.pem semaphore:/home/semaphore/.ssh
podman exec -it semaphore bash -c "cd /home/semaphore && unzip pfsso*.zip"
podman exec -it semaphore bash -c "cd /home/semaphore/pfsso-0.9.4 && python3 -m pip install --upgrade ."
podman exec -it semaphore bash -c "wget -P /home/semaphore https://raw.githubusercontent.com/UNiXMIT/UNiXIaC/main/sso.sh"
podman exec -it semaphore bash -c "chmod +x /home/semaphore/sso.sh"