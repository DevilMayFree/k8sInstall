#!/bin/bash

echo "Update the initial k8s environment, the host is not updated, it needs to be updated manually"

source "./parse.sh"

# Exceute
parse_info

all_node_ip_arr=(${master_ip_arr[@]} ${worker_ip_arr[@]})

echo "All node ip addresses:"
echo ${all_node_ip_arr[*]}

local_ip=$(hostname -I|awk '{print $1}')

# Log in to each node for the first time
for i in ${all_node_ip_arr[*]}; do
    remote_ip="${i}"
    if [ "$local_ip" == "$remote_ip" ]; then
        continue
    fi

    echo "Initialize k8s environment ip:""${remote_ip}"
    ssh -o StrictHostKeyChecking=no root@${remote_ip} "$(< './1_init_env.sh')"
done

echo "success!" && exit 0