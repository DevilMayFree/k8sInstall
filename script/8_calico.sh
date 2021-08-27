#!bin/bash

echo "安装网络插件calico && CoreDNS"

cd ~/component
echo "install calico"
kubectl apply -f calico.yaml
echo "calico success!"


# 设置 coredns 的 cluster-ip
COREDNS_CLUSTER_IP=10.233.0.10

echo "install coredns"
# 替换cluster-ip
sed -i "s/\${COREDNS_CLUSTER_IP}/${COREDNS_CLUSTER_IP}/g" coredns.yaml
# 创建 coredns
kubectl apply -f coredns.yaml
echo "coredns success!"

echo "install nodelocaldns"
# 替换cluster-ip
sed -i "s/\${COREDNS_CLUSTER_IP}/${COREDNS_CLUSTER_IP}/g" nodelocaldns.yaml
# 创建 nodelocaldns
kubectl apply -f nodelocaldns.yaml
echo "nodelocaldns success!"

echo "success!" && exit 0

