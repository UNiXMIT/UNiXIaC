FROM rockylinux:9
EXPOSE 8080
COPY pfsso*.zip /root
COPY support.pem /root/.ssh
COPY nginx.conf /etc/nginx/default.d/semaphore.conf
COPY semaphore.service /etc/systemd/system/semaphore.service
RUN dnf install epel-release -y; \
    dnf install ansible wget git python3 python3-pip tmux unzip python-winrm nginx -y; \
    dnf clean all; \
    curl -o /usr/bin/systemctl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py; \
    chmod +x /usr/bin/systemctl; \
    ansible-galaxy collection install amazon.aws; \
    python3 -m pip install boto3 pexpect pypsrp pywinrm; \
    wget -P /root https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.90/semaphore_2.8.90_linux_amd64.rpm; \
    dnf install /root/semaphore*.rpm; \
    chmod 600 /root/.ssh/support.pem; \
    cd /root && unzip pfsso*.zip; \
    python3 -m pip install --upgrade /root/pfsso*/; \
ENTRYPOINT [ "systemctl", "start", "nginx"]
