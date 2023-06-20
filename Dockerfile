FROM rockylinux:9
EXPOSE 80 443
COPY pfsso*.zip /root
COPY support.pem /root/.ssh
COPY semaphore.service /etc/systemd/system/semaphore.service
COPY config.json /root
COPY database.boltdb /root
COPY entrypoint.sh /root
RUN dnf install epel-release -y; \
    dnf install ansible wget git python3 python3-pip tmux unzip python-winrm nginx git -y; \
    dnf clean all; \
    curl -o /usr/bin/systemctl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py; \
    chmod +x /usr/bin/systemctl; \
    ansible-galaxy collection install amazon.aws; \
    python3 -m pip install boto3 pexpect pypsrp pywinrm; \
    wget -P /root https://github.com/ansible-semaphore/semaphore/releases/download/v2.8.90/semaphore_2.8.90_linux_amd64.rpm; \
    dnf install /root/semaphore*.rpm -y; \
    chmod 600 /root/.ssh/support.pem; \
    cd /root && unzip pfsso*.zip; \
    python3 -m pip install --upgrade /root/pfsso*/; \ 
    mv /etc/nginx /etc/nginxOriginal; \
    cd /etc && git clone https://github.com/h5bp/server-configs-nginx.git nginx; \
    sed -i 's/www-data/nginx/g' /etc/nginx/nginx.conf; \
    mv /etc/nginx/conf.d/no-ssl.default.conf /etc/nginx/conf.d/.no-ssl.default.conf; \
    mkdir /etc/nginx/certs; \
    mkdir /var/www; \
    chmod +x /root/entrypoint.sh
COPY semaphoreBasic.conf /etc/nginx/conf.d/semaphoreBasic.conf
COPY semaphoreTLS.conf /etc/nginx/conf.d/.semaphoreTLS.conf
# COPY cert.pem /etc/nginx/certs/cert.pem
# COPY key.pem /etc/nginx/certs/key.pem
ENTRYPOINT [ "/root/entrypoint.sh" ]
