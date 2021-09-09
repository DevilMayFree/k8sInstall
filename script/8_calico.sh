#!bin/bash

echo "Install network plug-in calico && CoreDNS"

cd /root/component
echo "install calico"
kubectl apply -f calico.yaml
echo "calico success!"


# set coredns  cluster-ip
COREDNS_CLUSTER_IP=10.233.0.10

echo "install coredns"
# sed cluster-ip
sed -i "s/\${COREDNS_CLUSTER_IP}/${COREDNS_CLUSTER_IP}/g" coredns.yaml
# create coredns
kubectl apply -f coredns.yaml
echo "coredns success!"

echo "install nodelocaldns"
# sed cluster-ip
sed -i "s/\${COREDNS_CLUSTER_IP}/${COREDNS_CLUSTER_IP}/g" nodelocaldns.yaml
# create nodelocaldns
kubectl apply -f nodelocaldns.yaml
echo "nodelocaldns success!"

echo "success!" && exit 0

