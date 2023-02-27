#!/bin/bash
if [[ $1 = "destroy" ]]; then
    terraform -chdir=rhel9/ destroy
else
    terraform -chdir=rhel9/ init
    terraform -chdir=rhel9/ plan
    terraform -chdir=rhel9/ apply -auto-approve
fi
