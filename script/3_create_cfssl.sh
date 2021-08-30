#!/bin/bash

echo "cfssl生成证书"

# 加载解析的配置文件内容
source "./parse.sh"

# Exceute
parse_info

# apiserver的service ip地址（一般是svc网段的第一个ip）
KUBERNETES_SVC_IP="10.233.0.1"
# 所有的master内网ip，逗号分隔（云环境可以加上master公网ip以便支持公网ip访问）
# MASTER_IPS=${master_ip_arr[@]}
# worker节点
# WORKERS=${worker_name_arr[@]}
# WORKER_IPS=${worker_ip_arr[@]}


cd /root/component/cfssl
cfssl_file="/root/component/cfssl/cfssl"
cfssljson_file="/root/component/cfssl/cfssljson"

if [[ ! -f "${cfssl_file}" ]]; then
	echo "cannot not find cfssl!" && exit 1
fi

if [[ ! -f "${cfssljson_file}" ]]; then
	echo "cannot not find cfssljson!" && exit 1
fi

mv ${cfssl_file} /usr/local/bin
mv ${cfssljson_file} /usr/local/bin

chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson

echo "cfssl version:"
cfssl version

mkdir /root/pki && cd /root/pki

echo "1、根证书创建"

cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "876000h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "876000h"
      }
    }
  }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

ls -la

echo "1.1 创建etcd证书"

# 拼接etcd集群信息
etcd_cluster=""
for ((i=0; i<${#etcd_name_arr[@]}; ++i)); do
    etcd_name=${etcd_name_arr[i]}
    etcd_cluster="${etcd_cluster}"\""${etcd_name}"\"","
done
etcd_cluster="${etcd_cluster::-1}"

cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "hosts": [
    ${etcd_cluster}
  ],
  "names": [
    {
      "C": "CN",
      "ST": "shenzhen",
      "L": "shenzhen",
      "O": "etcd",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=etcd etcd-csr.json | cfssljson -bare etcd

echo "2、admin客户端证书"

cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "seven"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  admin-csr.json | cfssljson -bare admin


echo "3、kubelet客户端证书"

for ((i=0;i<${#worker_name_arr[@]};i++)); do
echo "" ${worker_name_arr[$i]}
cat > ${worker_name_arr[$i]}-csr.json <<EOF
{
  "CN": "system:node:${worker_name_arr[$i]}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "L": "Beijing",
      "O": "system:nodes",
      "OU": "seven",
      "ST": "Beijing"
    }
  ]
}
EOF
cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${worker_name_arr[$i]},${worker_ip_arr[$i]} \
  -profile=kubernetes \
  ${worker_name_arr[$i]}-csr.json | cfssljson -bare ${worker_name_arr[$i]}
done

echo "4、kube-controller-manager客户端证书"

cat > kube-controller-manager-csr.json <<EOF
{
    "CN": "system:kube-controller-manager",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "system:kube-controller-manager",
        "OU": "seven"
      }
    ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

echo "5、kube-proxy客户端证书"

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy

echo "6、kube-scheduler客户端证书"

cat > kube-scheduler-csr.json <<EOF
{
    "CN": "system:kube-scheduler",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
      {
        "C": "CN",
        "ST": "BeiJing",
        "L": "BeiJing",
        "O": "system:kube-scheduler",
        "OU": "seven"
      }
    ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-scheduler-csr.json | cfssljson -bare kube-scheduler

echo "7、kube-apiserver服务端证书"

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF

printf -v joined '%s,' "${master_ip_arr[@]}"
echo "${joined%,}"

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=${KUBERNETES_SVC_IP},${joined%,},127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

echo "8、Service Account证书"

cat > service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  service-account-csr.json | cfssljson -bare service-account


echo "9、proxy-client 证书"

cat > proxy-client-csr.json <<EOF
{
  "CN": "aggregator",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "seven"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  proxy-client-csr.json | cfssljson -bare proxy-client


echo "10、分发客户端、服务端证书"

for instance in ${worker_name_arr[@]}; do
  scp ca.pem kubernetes-key.pem kubernetes.pem \
   ${instance}-key.pem ${instance}.pem root@${instance}:~/
done

for instance in ${etcd_name_arr[@]}; do
  scp ca.pem etcd-key.pem etcd.pem \
   ${instance}-key.pem ${instance}.pem root@${instance}:~/
done

OIFS=$IFS
IFS=','
for instance in ${master_ip_arr[@]}; do
  scp ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
    service-account-key.pem service-account.pem proxy-client.pem proxy-client-key.pem root@${instance}:~/
done
IFS=$OIFS

echo "success!" && exit 0
