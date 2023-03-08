#!/bin/bash
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook main.yml -i inventory --extra-vars "@variables.json"