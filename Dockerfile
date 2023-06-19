FROM rockylinux:9
EXPOSE 3000
COPY pfsso*.zip /root
COPY support.pem /root/.ssh
RUN dnf install epel-release -y; \
    dnf install ansible wget git python3 python3-pip tmux unzip python-winrm -y; \
    ansible-galaxy collection install amazon.aws; \
    python3 -m pip install boto3 pexpect pypsrp pywinrm; \
    wget -P /root https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.90/semaphore_2.8.90_linux_amd64.rpm; \
    dnf install /root/semaphore*.rpm; \
    cd /root && semaphore setup; \
    chmod 600 /root/.ssh/support.pem; \
    cd /root && unzip pfsso*.zip; \
    python3 -m pip install --upgrade /root/pfsso*/; \
ENTRYPOINT ["/usr/bin/tmux", "new", "-d", "-s", "semaphore", "semaphore", "server", "--config", "config.json"]
