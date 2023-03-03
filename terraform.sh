#!/bin/bash
export ACTION=$1
export INSTANCE=$2
export TFUSR=$3
export TFPASS=$4

git pull
if [ -z "$INSTANCE" ] || [ -z "$ACTION" ]; then
    echo "No Action or Instance specified!"
    echo "Usage: terraform.sh create rhel9"
    echo "       terraform.sh destroy rhel9"
elif [ $ACTION = "destroy" ]; then
    terraform -chdir=$2 destroy
elif [ $ACTION = "create" ]; then
    terraform -chdir=$2 init
    terraform -chdir=$2 plan
    terraform -chdir=$2 apply -auto-approve -var username=$TFUSER -var password=$TFPASS
else
    echo "Invalid Action specified!"
    echo "Usage: terraform.sh create rhel9"
    echo "       terraform.sh destroy rhel9"
fi