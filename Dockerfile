FROM semaphoreui/semaphore:CHANGEME
EXPOSE 3000
USER root
RUN apk add --no-cache python3 py3-pip py3-passlib
RUN pip install boto3 pexpect pypsrp pywinrm pywinrm[credssp]
RUN ansible-galaxy collection install amazon.aws:7.4.0 containers.podman:1.12.0 --collections-path /usr/lib/python3.11/site-packages/ansible_collections --force
USER semaphore
RUN mkdir -m 700 /home/semaphore/.ssh
COPY --chown=semaphore:root --chmod=0600 support.pem /home/semaphore/.ssh