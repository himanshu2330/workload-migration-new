#!/bin/bash
V_ticket=`cat ./new_request.txt | awk -F "," '{print $1}'`
for i in ${V_ticket[@]}
do
  $(cd Scripts/ ; sh Createparameterjson.sh)

  ansible-playbook main.yml --tags='ClusterInfo'

  ansible-playbook main.yml --tags='VMInfo'
 
  ansible-playbook main.yml --tags='Validate'

  ansible-playbook main.yml --tags='Email'

#  ansible-playbook main.yml --tags='MigrateVM'

#  rm -rf Parameter/parameters.json

done

