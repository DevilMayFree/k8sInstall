#!/bin/bash

echo "部署kubernetes控制平面"
echo "运行在每个master节点"

# 加载解析的配置文件内容
source "./parse.sh"

# Exceute
parse_info

# 拼接etcd信息
etcd_servers=""
for ((i=0; i<${#etcd_ip_arr[@]}; ++i)); do
    etcd_ip=${etcd_ip_arr[$i]}
    etcd_servers="${etcd_servers}https://"${etcd_ip}":2379,"
done
etcd_servers="${etcd_servers::-1}"

# apiserver实例数
apiserver_count=${#master_name_arr[@]}
echo "apiserver实例数:"
echo ${apiserver_count}

# master节点
for instance in ${master_name_arr[@]}; do
    ssh -o StrictHostKeyChecking=no root@${instance} "bash -s" < k8s_controller_inner.sh ${apiserver_count} ${etcd_servers}
done

echo "success!" && exit 0














