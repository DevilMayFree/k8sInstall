#!/bin/bash

# ---- init env start ----

echo "This script is suitable for centos7 and will initialize the k8s environment"

# Alibaba CentOS7 source
cat > /etc/yum.repos.d/ali-docker-ce.repo <<-'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF

# tsinghua Source
cat > /etc/yum.repos.d/th-docker-ce.repo <<-'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/7/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF

# k8s Source
cat > /etc/yum.repos.d/kubernetes.repo <<-'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


# Alibaba centos7 Source
curl -o /etc/yum.repos.d/aliyun.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -ri -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' -e 's/\$releasever/7/g' /etc/yum.repos.d/aliyun.repo

# update
yum update -y --exclude=kernel*

# install epel source, used to install container-selinux
yum install -y epel-release

## Install the base package
yum install -y bash-completion ntp net-tools python-pip \
	tree wget make cmake gcc gcc-c++ createrepo \
	device-mapper-persistent-data lvm2 psmisc vim \
	lrzsz git vim-enhanced ntpdate ipvsadm conntrack-tools \
	socat conntrack ipvsadm ipset jq sysstat curl iptables libseccomp yum-utils


# Turn off the firewall
systemctl stop firewalld && systemctl disable firewalld

systemctl start ntp && systemctl enable ntpd

# SELINUX
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disable/' /etc/selinux/config


# Set iptables rules
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT

# Close swap
swapoff -a && free –h
sed -i 's/.*swap.*/#&/g' /etc/fstab

# Close dnsmasq
service dnsmasq stop && systemctl disable dnsmasq

# Load the kernel module
modprobe ip_vs_rr
modprobe br_netfilter

# Time synchronization
yum install ntpdate -y
ntpdate ntp.api.bz

# Tuning system TimeZone
timedatectl set-timezone Asia/Shanghai

# The current UTC time is written to the hardware clock
timedatectl set-local-rtc 0

# Resource limit
if [ `ulimit -n` -lt 65536 ]; then
    {
    echo "*    soft    nofile    655360"
    echo "*    hard    nofile    131072"
    echo "*    soft    nproc    655350"
    echo "*    hard    nproc    655350"
    echo "*    soft    memlock    unlimited"
    echo "*    hard    memlock    unlimited"
    } >> /etc/security/limits.conf
fi


# Make a configuration file
cat > /etc/sysctl.d/kubernetes.conf <<-'EOF'
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
vm.swappiness = 0
vm.overcommit_memory = 1
EOF

# Effective
sysctl -p /etc/sysctl.d/kubernetes.conf

# pip
pip install --upgrade pip

echo "success!" && exit 0