#!/bin/bash
podman pull rockylinux:8
podman run -it -d --name ROCKY rockylinux:8
podman exec -it ROCKY dnf update -y
podman exec -it ROCKY dnf install epel-release -y
podman exec -it ROCKY dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
podman exec -it ROCKY dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
podman exec -it ROCKY dnf install terraform git python39 python3-pip ansible sshpass gh unzip -y
podman exec -it ROCKY python3 -m pip install install cryptography -U
podman exec -it ROCKY gh auth login
podman exec -it ROCKY gh repo clone UNiXMIT/UNiXIaC
podman exec -it ROCKY bash chmod +x UNiXIaC/*.sh
podman exec -it ROCKY unzip /UNiXIaC/pfsso*.zip -d /UNiXIaC
podman exec -it ROCKY python3 -m pip install --upgrade /UNiXIaC/pfsso-0.9.4
podman exec -it ROCKY bash /UNiXIaC/sso.sh
podman exec -it ROCKY mkdir /root/.ssh
podman exec -it ROCKY touch /root/.ssh/known_hosts
podman exec -it ROCKY cp /UNiXIaC/support.pem /root/.ssh
podman exec -it ROCKY bash /UNiXIaC/terraform.sh create /UNiXIaC/rhel9
podman exec -it ROCKY bash /UNiXIaC/terraform.sh destroy /UNiXIaC/rhel9