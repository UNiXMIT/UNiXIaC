#!/bin/bash
export AWSEXP=$(echo $(( ($(date +%s) - $(stat ~/.aws/credentials -c %Y)) / 60 )))
if [ $AWSEXP -ge 60 ]; then
    pfsso -a -s 1 -2 ask
fi
cat ~/.aws/credentials | grep aws_access_key_id
cat ~/.aws/credentials | grep aws_secret_access_key
cat ~/.aws/credentials | grep aws_session_token
