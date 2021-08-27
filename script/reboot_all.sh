#!/bin/bash

echo "重启全部远程主机"

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

    echo "重启主机 ip:""${remote_ip}"
    ssh -o StrictHostKeyChecking=no root@${remote_ip} "reboot"
done

echo "success!" && exit 0