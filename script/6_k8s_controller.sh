#!/bin/bash

echo "Deploy kubernetes control plane"
echo "Run on each master node"

# Load the content of the parsed configuration file
source "./parse.sh"

# Exceute
parse_info

# Splicing etcd information
etcd_servers=""
for ((i=0; i<${#etcd_ip_arr[@]}; ++i)); do
    etcd_ip=${etcd_ip_arr[$i]}
    etcd_servers="${etcd_servers}https://"${etcd_ip}":2379,"
done
etcd_servers="${etcd_servers::-1}"

# apiserver instances
apiserver_count=${#master_name_arr[@]}
echo "apiserver instances:"
echo ${apiserver_count}

# master nodes
for instance in ${master_name_arr[@]}; do
    ssh -o StrictHostKeyChecking=no root@${instance} "bash -s" < k8s_controller_inner.sh ${apiserver_count} ${etcd_servers}
done

echo "success!" && exit 0














