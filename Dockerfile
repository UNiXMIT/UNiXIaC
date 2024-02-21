FROM semaphoreui/semaphore:latest
EXPOSE 3000
USER root
RUN apk add --no-cache python3 py3-pip passlib
RUN pip install boto3 pexpect pypsrp pywinrm pywinrm[credssp]
RUN ansible-galaxy collection install amazon.aws
COPY pfsso*.zip /home/semaphore
RUN cd /home/semaphore && unzip pfsso*.zip; \
    pip install --upgrade /home/semaphore/pfsso*/
USER semaphore
RUN mkdir -m 700 /home/semaphore/.ssh
COPY --chown=semaphore:root --chmod=0600 support.pem /home/semaphore/.ssh