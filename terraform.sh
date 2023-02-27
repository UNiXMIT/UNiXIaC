#!/bin/bash
export ACTION=$1
export INSTANCE=$2

if [ -z "$INSTANCE" ] || [ -z "$ACTION" ]; then
    echo "Invalid or no option specified!"
    echo "Usage: terraform.sh create rhel9"
    echo "       terraform.sh destroy rhel9"
elif [ $ACTION = "destroy" ]; then
    terraform -chdir=$2 destroy
elif [ $ACTION = "create" ]; then
    terraform -chdir=$2 init
    terraform -chdir=$2 plan
    terraform -chdir=$2 apply -auto-approve
else
    echo "Invalid or no option specified!"
    echo "Usage: terraform.sh create rhel9"
    echo "       terraform.sh destroy rhel9"
fi