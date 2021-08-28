#!/bin/bash

echo "部署ETCD集群"

# 加载解析的配置文件内容
source "./parse.sh"

# Exceute
parse_info

# local
ETCD_NAME=$(hostname -s)
ETCD_IP=$(hostname -I|awk '{print $1}')

# 拼接集群信息
initial_cluster=""
for ((i=0; i<${#etcd_name_arr[@]}; ++i)); do
    etcd_ip=${etcd_ip_arr[$i]}
    etcd_name=${etcd_name_arr[i]}
    initial_cluster="${initial_cluster}${etcd_name}=https://"${etcd_ip}":2380,"
done
initial_cluster="${initial_cluster::-1}"

for instance in ${etcd_name_arr[@]}; do
    ssh root@${instance} "$(< './etcd_cluster_inner.sh')"
done

echo "集群服务设置完成"

# 启动etcd集群
for instance in ${etcd_name_arr[@]}; do
    ssh root@${instance} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd"
done

echo "验证etcd集群"
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem

echo "success!" && exit 0






