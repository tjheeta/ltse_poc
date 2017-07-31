#!/bin/sh

ansible-playbook --extra-vars "kops_create=True" -i inventory --vault-password-file=/tmp/tmp.txt main.yml
