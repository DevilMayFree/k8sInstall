#!/bin/bash

echo "更新远程主机内核,本主机不更新,需要手动更新"

source "./parse.sh"

#Exceute
parse_info

all_node_ip_arr=(${master_ip_arr[@]} ${worker_ip_arr[@]})

echo "所有的节点ip地址:"
echo ${all_node_ip_arr[*]}

local_ip=$(hostname -I|awk '{print $1}')

# 首次登录每个节点
for i in ${all_node_ip_arr[*]}; do
    remote_ip="${i}"
    if [ "$local_ip" == "$remote_ip" ]; then
        continue
    fi

    echo "更新内核 ip:""${remote_ip}"
    ssh -o StrictHostKeyChecking=no root@${remote_ip} "$(< './0_update_kernel.sh')"
done

echo "success!" && exit 0