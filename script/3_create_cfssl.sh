#!/bin/bash

echo "cfssl generates a certificate"

# Load the content of the parsed configuration file
source "./parse.sh"

# Exceute
parse_info

# The service ip address of apiserver (usually the first ip of the svc network segment)
KUBERNETES_SVC_IP="10.233.0.1"

cd /root/component/cfssl
cfssl_file="/root/component/cfssl/cfssl"
cfssljson_file="/root/component/cfssl/cfssljson"

# Check if cfssl and cfssljson exist
if [[ ! -f "${cfssl_file}" ]]; then
	echo "cannot not find cfssl!" && exit 1
fi

if [[ ! -f "${cfssljson_file}" ]]; then
	echo "cannot not find cfssljson!" && exit 1
fi

cp ${cfssl_file} /usr/local/bin
cp ${cfssljson_file} /usr/local/bin

chmod +x /usr/local/bin/cfssl /usr/local/bin/cfssljson

echo "cfssl version:"
cfssl version

mkdir /root/pki && cd /root/pki

echo "1、ca.pem create"

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

echo "1.1 create etcd certificate"

# 拼接etcd集群信息
etcd_cluster=""
all_etcd_arr=(${etcd_name_arr[@]} ${etcd_ip_arr[@]})
for ((i=0; i<${#all_etcd_arr[@]}; ++i)); do
    etcd_name=${all_etcd_arr[i]}
    etcd_cluster="${etcd_cluster}"\""${etcd_name}"\"","
done
etcd_cluster="${etcd_cluster::-1}"

cat > etcd-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "hosts": [
    ${etcd_cluster}
  ],
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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd

echo "2、admin clients certificate"

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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin

echo "3、kubelet clients certificate"

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
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${worker_name_arr[$i]},${worker_ip_arr[$i]} -profile=kubernetes ${worker_name_arr[$i]}-csr.json | cfssljson -bare ${worker_name_arr[$i]}
done

echo "4、kube-controller-manager clients certificate"

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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

echo "5、kube-proxy clients certificate"

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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

echo "6、kube-scheduler clients certificate"

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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler

echo "7、kube-apiserver servers certificate"

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

# Splicing node IP information
ip_cluster=""
all_ip_arr=(${master_ip_arr[@]} ${worker_ip_arr[@]} ${etcd_ip_arr[@]})

# De-duplication
distinct_ip_arr=($(awk -v RS=' ' '!a[$1]++' <<< ${all_ip_arr[@]}))

# Splicing
for ((i=0; i<${#distinct_ip_arr[@]}; ++i)); do
    temp_ip=${distinct_ip_arr[i]}
    ip_cluster="${ip_cluster}""${temp_ip}"","
done
ip_cluster="${ip_cluster::-1}"

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -hostname=${KUBERNETES_SVC_IP},${ip_cluster},127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

echo "8、Service Account certificate"

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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes service-account-csr.json | cfssljson -bare service-account

echo "9、proxy-client certificate"

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

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes proxy-client-csr.json | cfssljson -bare proxy-client


echo "10、distribute clients 、 servers certificate"

for instance in ${worker_name_arr[@]}; do
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem ${instance}-key.pem ${instance}.pem root@${instance}:~/
done

for instance in ${etcd_name_arr[@]}; do
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ca.pem etcd-key.pem etcd.pem kubernetes-key.pem kubernetes.pem root@${instance}:~/
done

OIFS=$IFS
IFS=','
for instance in ${master_ip_arr[@]}; do
  scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem proxy-client.pem proxy-client-key.pem root@${instance}:~/
done
IFS=$OIFS

echo "success!" && exit 0
