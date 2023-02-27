#!/bin/bash
if [ $1="destroy"]
then
    terraform -chdir=wins2022/ destroy
else
    terraform -chdir=wins2022/ init
    terraform -chdir=wins2022/ plan
    terraform -chdir=wins2022/ apply -auto-approve
fi
