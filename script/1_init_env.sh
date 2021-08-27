#!/bin/bash

# ---- init env start ----

echo "本脚本适合centos7,将初始化k8s环境"

# 阿里云 CentOS7 源
cat > /etc/yum.repos.d/ali-docker-ce.repo <<-'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://mirrors.aliyun.com/docker-ce/linux/centos/7/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/docker-ce/linux/centos/gpg
EOF

# 清华镜像源
cat > /etc/yum.repos.d/th-docker-ce.repo <<-'EOF'
[docker-ce-stable]
name=Docker CE Stable - $basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/7/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/gpg
EOF

# k8s 源
cat > /etc/yum.repos.d/kubernetes.repo <<-'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF


# 阿里云CentOS7源
curl -o /etc/yum.repos.d/aliyun.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -ri -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' -e 's/\$releasever/7/g' /etc/yum.repos.d/aliyun.repo

# 更新
yum update -y --exclude=kernel*

# 安装 epel 源，用于安装 container-selinux
yum install -y epel-release

## 安装基础包
yum install -y bash-completion net-tools \
	tree wget make cmake gcc gcc-c++ createrepo \
	device-mapper-persistent-data lvm2 psmisc vim \
	lrzsz git vim-enhanced ntpdate ipvsadm conntrack-tools \
	socat conntrack ipvsadm ipset jq sysstat curl iptables libseccomp yum-utils


# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld

# SELINUX
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disable/' /etc/selinux/config


# 设置iptables规则
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT

# 关闭swap
swapoff -a && free –h
sed -i 's/.*swap.*/#&/g' /etc/fstab

# 关闭dnsmasq
service dnsmasq stop && systemctl disable dnsmasq

# 加载内核模块
modprobe ip_vs_rr
modprobe br_netfilter

# 时间同步
yum install ntpdate -y
ntpdate ntp.api.bz

# 调整系统 TimeZone
timedatectl set-timezone Asia/Shanghai

# 当前的 UTC 时间写入硬件时钟
timedatectl set-local-rtc 0

# 资源限制
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


# 制作配置文件
cat > /etc/sysctl.d/kubernetes.conf <<-'EOF'
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
vm.swappiness = 0
vm.overcommit_memory = 1
EOF

# 生效文件
sysctl -p /etc/sysctl.d/kubernetes.conf

echo "success!" && exit 0