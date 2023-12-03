FROM semaphoreui/semaphore:latest
EXPOSE 3000
USER root
RUN apk add --no-cache python3 py3-pip passlib
RUN pip install boto3 pexpect pypsrp pywinrm
RUN ansible-galaxy collection install amazon.aws
COPY pfsso*.zip /home/semaphore
RUN cd /home/semaphore && unzip pfsso*.zip; \
    pip install --upgrade /home/semaphore/pfsso*/