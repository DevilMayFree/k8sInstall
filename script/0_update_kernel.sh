#!/bin/bash

# ---- update kernel start ----

echo "本脚本适合centos7,将更新内核版本至最新稳定版,更新后重启"

# 当前系统版本
echo "current kernel:"
cat /etc/redhat-release
uname -sr

yum update -y

# 添加第三方yum源
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm

# 可安装的内核包
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available

# 安装内核
yum -y --enablerepo=elrepo-kernel install kernel-ml

# 修改grub2
grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg

# 在 Centos/RedHat Linux 7 中启用 user namespace
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

# 检查确认启动的 namespace, 如果是 y，则启用了对应的namespace，否则未启用
grep "CONFIG_[USER,IPC,PID,UTS,NET]*_NS" $(ls /boot/config*|tail -1)

# 在 Centos/RedHat Linux 7 中关闭 user namespace
grubby --remove-args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

# check
grubby --default-kernel

# 内核版本
echo "updated kernel:"
uname -sr

# ---- update kernel end ----

# 重启
reboot