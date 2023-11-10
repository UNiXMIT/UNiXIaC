# BUILD
## podman build --tag mf/semaphore -f Dockerfile

# RUN
## podman run -p 3001:3000 --name semaphore \
##     -v /home/support/semaphore/config:/etc/semaphore \
##     -v /home/support/semaphore/db:/var/lib/semaphore \
##     -e SEMAPHORE_DB_DIALECT=bolt \
##     -e SEMAPHORE_ADMIN=admin \
##     -e SEMAPHORE_ADMIN_PASSWORD=strongPassword123 \
##     -e SEMAPHORE_ADMIN_NAME=Admin \
##     -e SEMAPHORE_ADMIN_EMAIL=admin@localhost \
##     -d mf/semaphore

FROM semaphoreui/semaphore:latest
USER root
RUN apk add --no-cache python3 py3-pip
RUN pip install boto3 pexpect pypsrp pywinrm
RUN ansible-galaxy collection install amazon.aws
COPY pfsso*.zip /home/semaphore
RUN cd /home/semaphore && unzip pfsso*.zip; \
    pip install --upgrade /home/semaphore/pfsso*/
USER semaphore
RUN mkdir -m 700 /home/semaphore/.ssh
COPY --chown=semaphore:root --chmod=0600 support.pem /home/semaphore/.ssh