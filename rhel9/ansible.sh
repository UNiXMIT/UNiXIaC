#!/bin/bash
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook main.yml -i inventory.ini --tags "default" --extra-vars "@variables.json"