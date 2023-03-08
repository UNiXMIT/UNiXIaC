#!/bin/bash
export AWSEXP=$(echo $(( ($(date +%s) - $(stat ~/.aws/credentials -c %Y)) / 60 )))
if [ $AWSEXP -ge 60 ]; then
    pfsso -s 1 -2 ask
fi