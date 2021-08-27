#!/bin/bash

echo "部署kubernetes控制平面"
echo "运行在每个master节点"

# 加载解析的配置文件内容
source "./parse.sh"

# Exceute
parse_info

# master节点
MASTERS=${master_name_arr[@]}

for instance in ${MASTERS}; do
    ssh root@${instance} "$(< './6_k8s_controller_inner.sh')"
done

echo "success!" && exit 0














