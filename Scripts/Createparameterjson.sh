#!/bin/bash  

  cp ../Template/sample_parameters.json  parameters.json 
  V_request=`cat ../new_request.txt | awk -F "," '{print $1}'`
  VM=`cat ../new_request.txt | awk -F "vm_to_be_migrated':" '{print $2}' | awk -F "'" '{print $2}'`
  source_vcenter_ip=`cat ../new_request.txt | awk -F "source_vcenter_ip':" '{print $2}' | awk -F "'" '{print $2}'`
  destination_vcenter_ip=`cat ../new_request.txt | awk -F "destination_vcenter_ip':" '{print $2}' | awk -F "'" '{print $2}'`
  source_vcenter_cluster=`cat ../new_request.txt | awk -F "source_vcenter_cluster':" '{print $2}' | awk -F "'" '{print $2}'`
  destination_vcenter_cluster=`cat ../new_request.txt | awk -F "destination_vcenter_cluster':" '{print $2}' | awk -F "'" '{print $2}'`
  requester_email_id=`cat ../new_request.txt | awk -F "requester_email':" '{print $2}' | awk -F "'" '{print $2}'`
  sed -i "s/ticket/$V_request/g" "parameters.json"
  sed -i "s/source_vcenter_ip/$source_vcenter_ip/g" "parameters.json"
  sed -i  "s/vm_to_be_migrated/$VM/g" "parameters.json"
  sed -i  "s/destination_vcenter_ip/$destination_vcenter_ip/g" "parameters.json"
  sed -i  "s/source_vcenter_cluster/$source_vcenter_cluster/g" "parameters.json"
  sed -i  "s/destination_vcenter_cluster/$destination_vcenter_cluster/g" "parameters.json"
  sed -i  "s/emailrequester/$requester_email_id/g" "parameters.json"
  mv parameters.json ../Parameter/
