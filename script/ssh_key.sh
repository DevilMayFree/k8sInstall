#!/bin/bash

echo "Use ssh-copy-id to copy all the current keys to the remote host"

source "./parse.sh"

# Exceute
parse_info

# Whether the rsa public key already exists
id_rsa_file="~/.ssh/id_rsa.pub"

if [[ ! -f "$id_rsa_file" ]]; then
    # Create a new one
    echo "run ssh-keygen ..."
    ssh-keygen -t rsa
fi

id_rsa=$(cat ~/.ssh/id_rsa.pub)

all_node_ip_arr=(${master_ip_arr[@]} ${worker_ip_arr[@]})
all_node_name_arr=(${master_name_arr[@]} ${worker_name_arr[@]})
all_hosts=""

echo "All node ip addresses:"
echo ${all_node_ip_arr[*]}
echo ""
echo "Hostname of all nodes:"
echo ${all_node_name_arr[*]}

# Log in to each node for the first time
for i in ${all_node_ip_arr[*]}; do
    ip_arr="${i}"
    echo "ip_arr "${ip_arr}" password:"
    ssh-copy-id -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no root@${ip_arr}
done

# Generate complete hosts
for ((i=0; i<${#all_node_name_arr[@]}; ++i)); do
    remote_ip=${all_node_ip_arr[$i]}
    remote_hostname=${all_node_name_arr[i]}
    all_hosts="${all_hosts}${remote_ip}""    ""${remote_hostname}""\n"
done

# Set hostname for each node and add hosts
for ((i=0; i<${#all_node_name_arr[@]}; ++i)); do
    remote_ip=${all_node_ip_arr[$i]}
    remote_hostname=${all_node_name_arr[i]}
    echo "ip:""${remote_ip}" ";set hostname:" "${remote_hostname}"
    ssh -o StrictHostKeyChecking=no root@${remote_ip} "hostnamectl set-hostname ${remote_hostname}; echo -e '${all_hosts}' >> /etc/hosts"
done

echo "success!" && exit 0
