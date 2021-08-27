#!/bin/bash

echo "使用ssh-copy-id复制当前所有key到远程主机"

source "./parse.sh"

#Exceute
parse_info

# 是否已经存在rsa公钥
id_rsa_file="~/.ssh/id_rsa.pub"

if [[ ! -f "$id_rsa_file" ]]; then
    # 创建一个新的
    echo "run ssh-keygen ..."
    ssh-keygen -t rsa
fi

id_rsa=$(cat ~/.ssh/id_rsa.pub)

all_node_ip_arr=(${master_ip_arr[@]} ${worker_ip_arr[@]})
all_node_name_arr=(${master_name_arr[@]} ${worker_name_arr[@]})
all_hosts=""

echo "所有的节点ip地址:"
echo ${all_node_ip_arr[*]}
echo ""
echo "所有节点hostname:"
echo ${all_node_name_arr[*]}

# 首次登录每个节点
for i in ${all_node_ip_arr[*]}; do
    ip_arr="${i}"
    echo "ip_arr "${ip_arr}" password:"
    ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@${ip_arr}
done

# 生成完整hosts
for ((i=0; i<${#all_node_name_arr[@]}; ++i)); do
    remote_ip=${all_node_ip_arr[$i]}
    remote_hostname=${all_node_name_arr[i]}
    all_hosts="${all_hosts}${remote_ip}""    ""${remote_hostname}""\n"
done

# 每个节点设置hostname并添加hosts
for ((i=0; i<${#all_node_name_arr[@]}; ++i)); do
    remote_ip=${all_node_ip_arr[$i]}
    remote_hostname=${all_node_name_arr[i]}
    echo "ip:""${remote_ip}" ";set hostname:" "${remote_hostname}"
    ssh -o StrictHostKeyChecking=no root@${remote_ip} "hostnamectl set-hostname ${remote_hostname}; echo -e '${all_hosts}' >> /etc/hosts"
done

echo "success!" && exit 0
