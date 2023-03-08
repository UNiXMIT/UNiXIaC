#!/bin/bash
export ACTION=$1
export INSTANCE=$2
export TFUSR=$3
export TFPASS=$4
export TFPATH="$(dirname -- "${BASH_SOURCE[0]}")"

cd $TFPATH
git pull
chmod +x *.sh
./sso.sh
if [ -z "$INSTANCE" ] || [ -z "$ACTION" ]; then
    echo "No Action or Instance specified!"
    echo "Usage: terraform.sh create rhel9 username password"
    echo "       terraform.sh destroy rhel9"
elif [ $ACTION = "destroy" ]; then
    terraform -chdir=$2 destroy
elif [ $ACTION = "create" ]; then
    terraform -chdir=$2 init
    terraform -chdir=$2 plan
    terraform -chdir=$2 apply -auto-approve -var username=$TFUSR -var password=$TFPASS
else
    echo "Invalid Action specified!"
    echo "Usage: terraform.sh create rhel9 username password"
    echo "       terraform.sh destroy rhel9"
fi