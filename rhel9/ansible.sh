#!/bin/bash
ansible-playbook main.yml -i inventory --extra-vars "@variables.json"