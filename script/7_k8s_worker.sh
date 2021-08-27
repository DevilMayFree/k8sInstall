#!/bin/bash

echo "部署kubernetes工作节点"
echo "运行在每个worker节点"

# 加载解析的配置文件内容
source "./parse.sh"

# Exceute
parse_info

# worker节点
WORKERS=${worker_name_arr[@]}

for instance in ${WORKERS}; do
    ssh root@${instance} "$(< './7_k8s_worker_inner.sh')"
done

echo "success!" && exit 0














