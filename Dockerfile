FROM semaphoreui/semaphore:CHANGEME
EXPOSE 3000
USER root
# Copy specific pip configuration to the container. This is optional and can be used to configure pip settings.
# COPY pip.conf /etc/pip.conf
# RUN pip config list
RUN apk add --no-cache python3 py3-pip py3-passlib coreutils
RUN pip install ansible-core boto3 pypsrp pywinrm requests-credssp
# Forces the installation of a specific version of a collection.
# RUN ansible-galaxy collection install amazon.aws:10.3.0 containers.podman:1.19.0 --collections-path /opt/semaphore/apps/ansible/13.5.0/venv/lib/python3.12/site-packages/ansible_collections --force
USER semaphore
RUN mkdir -m 700 /home/semaphore/.ssh
COPY --chown=semaphore:root --chmod=0600 support.pem /home/semaphore/.ssh