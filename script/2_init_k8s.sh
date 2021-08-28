#!/bin/bash

echo "分发k8s软件"

containerd_version=1.5.5

# 加载解析的配置文件内容
source "./parse.sh"

# Exceute
parse_info

# 判断component文件夹是否存在


# 把master相关组件分发到master节点
cd ~/component/master
chmod +x kube*

for remote_ip in ${master_ip_arr[@]}; do
  scp kube-apiserver kube-controller-manager kube-scheduler kubectl root@${remote_ip}:/usr/local/bin/
done

# 把worker相关组件分发到worker节点
cd ~/component/worker
chmod +x kube*

for remote_ip in ${worker_ip_arr[@]}; do
  scp kubelet kube-proxy root@${remote_ip}:/usr/local/bin/
  scp cri-containerd-cni-${containerd_version}-linux-amd64.tar.gz root@${remote_ip}:/root
done

# 把etcd相关组件分发到etcd节点
cd ~/component/etcd
chmod +x etcd*

for remote_ip in ${etcd_ip_arr[@]}; do
  scp etcd etcdctl root@${remote_ip}:/usr/local/bin/
done