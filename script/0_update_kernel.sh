#!/bin/bash

# ---- update kernel start ----

echo "This script is suitable for centos7, will update the kernel version to the latest stable version, restart after the update"

# Current kernel version
echo "current kernel:"
cat /etc/redhat-release
uname -sr

yum update -y

# Add third-party yum source
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm

# Installable kernel package
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available

# Install the kernel
yum -y --enablerepo=elrepo-kernel install kernel-ml

# Modify grub2
grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg

# Enable user namespace in Centos/RedHat Linux 7
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

# Check to confirm the started namespace, if it is y, the corresponding namespace is enabled, otherwise it is not enabled
grep "CONFIG_[USER,IPC,PID,UTS,NET]*_NS" $(ls /boot/config*|tail -1)

# Close user namespace in Centos/RedHat Linux 7
grubby --remove-args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"

# check
grubby --default-kernel

# kernel version
echo "updated kernel:"
uname -sr

# ---- update kernel end ----

# reboot
reboot