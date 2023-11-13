#!/bin/bash

containerName=semaphore
containerRepo=mf/semaphore
runOptions=(
-v /home/support/semaphore/config:/etc/semaphore
-v /home/support/semaphore/db:/var/lib/semaphore
--restart always
-e SEMAPHORE_DB_DIALECT=bolt
-e SEMAPHORE_ADMIN=admin
-e SEMAPHORE_ADMIN_PASSWORD=strongPassword123
-e SEMAPHORE_ADMIN_EMAIL=admin@localhost
-p 3000:3000
--health-cmd "curl -sf http://domain.com:3000/api/auth/login  || exit 1"
--health-interval 1m
--health-timeout 2s
--health-retries 5
--health-start-period 5m
)

checkContainerRuntime() {
    printf "Checking Container Runtime...\n\n"
    containerRuntime=$(which docker 2>/dev/null) ||
        containerRuntime=$(which podman 2>/dev/null) ||
        {
            printf "!!!No docker or podman executable found in your PATH!!!\n\n"
            exit 1
        }
    printf "Using Container Runtime - ${containerRuntime}\n\n"
}

removeContainer() {
    if [[ -n "$(sudo ${containerRuntime} ps -a -q -f name=${containerName})" ]]; then
        printf "Removing Container...\n\n"
        sudo ${containerRuntime} stop ${containerName} >/dev/null
        sudo ${containerRuntime} wait ${containerName} >/dev/null
        sudo ${containerRuntime} rm ${containerName} >/dev/null
    fi
}

buildContainer() {
    printf "Building Container...\n\n"
    sudo ${containerRuntime} build --tag ${containerRepo} -f Dockerfile
}

startContainer() {
    printf "Starting Container...\n\n"
    sudo ${containerRuntime} run -d --name ${containerName} "${runOptions[@]}" ${containerRepo} 
}

checkContainerRuntime
removeContainer
buildContainer
startContainer