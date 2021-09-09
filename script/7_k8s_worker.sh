#!/bin/bash

echo "Deploy kubernetes worker nodes"
echo "Run on each worker node"

# Load the content of the parsed configuration file
source "./parse.sh"

# Exceute
parse_info

insert=""
for instance in ${master_ip_arr[@]}; do
    insert="${insert}server'  '${instance}:6443';''   '"
done

for instance in ${worker_name_arr[@]}; do
    ssh -o StrictHostKeyChecking=no root@${instance} "bash -s" < k8s_worker_inner.sh ${insert}
done

echo "success!" && exit 0














