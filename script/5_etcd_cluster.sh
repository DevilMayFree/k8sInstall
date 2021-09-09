#!/bin/bash

echo "Deploy an ETCD cluster"

# Load the content of the parsed configuration file
source "./parse.sh"

# Exceute
parse_info

# Splicing cluster information
initial_cluster=""
for ((i=0; i<${#etcd_name_arr[@]}; ++i)); do
    etcd_ip=${etcd_ip_arr[$i]}
    etcd_name=${etcd_name_arr[i]}
    initial_cluster="${initial_cluster}${etcd_name}=https://"${etcd_ip}":2380,"
done
initial_cluster="${initial_cluster::-1}"

for instance in ${etcd_name_arr[@]}; do
    ssh -o StrictHostKeyChecking=no root@${instance} "bash -s" < etcd_cluster_inner.sh ${initial_cluster}
done

echo "Cluster service setup is complete"

# Start etcd cluster
for instance in ${etcd_name_arr[@]}; do
    ssh -o StrictHostKeyChecking=no root@${instance} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd"
done

echo "Verify etcd cluster"
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/etcd.pem \
  --key=/etc/etcd/etcd-key.pem

echo "success!" && exit 0






