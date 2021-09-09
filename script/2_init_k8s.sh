#!/bin/bash

echo "Distribute k8s software"

containerd_version=1.5.5

# Load the content of the parsed configuration file
source "./parse.sh"

# Exceute
parse_info

# Distribute the master related components to the master node
cd /root/component/master
chmod +x kube*

for remote_ip in ${master_ip_arr[@]}; do
  scp kube-apiserver kube-controller-manager kube-scheduler kubectl root@${remote_ip}:/usr/local/bin/
done

# Distribute worker-related components to worker nodes
cd /root/component/worker
chmod +x kube*

for remote_ip in ${worker_ip_arr[@]}; do
  scp kubelet kube-proxy root@${remote_ip}:/usr/local/bin/
  scp cri-containerd-cni-${containerd_version}-linux-amd64.tar.gz root@${remote_ip}:/root
done

# Distribute etcd related components to etcd nodes
cd /root/component/etcd
chmod +x etcd*

for remote_ip in ${etcd_ip_arr[@]}; do
  scp etcd etcdctl root@${remote_ip}:/usr/local/bin/
done