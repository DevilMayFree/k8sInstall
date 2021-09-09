#!/bin/bash

echo "部署kubernetes工作节点"
echo "运行在每个worker节点"

# 加载解析的配置文件内容
source "./parse.sh"

# Exceute
parse_info

insert=""
for instance in ${master_ip_arr[@]}; do
    insert="${insert}server ${instance}:6443; "
done

for instance in ${worker_name_arr[@]}; do
    ssh -o StrictHostKeyChecking=no root@${instance} "bash -s" < k8s_worker_inner.sh ${insert}
done

echo "success!" && exit 0














