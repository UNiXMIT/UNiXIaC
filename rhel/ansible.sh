#!/bin/bash
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_PERSISTENT_COMMAND_TIMEOUT=120
ansible-playbook main.yml -i inventory.ini --tags "default" --extra-vars "@variables.json"