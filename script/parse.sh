#!/bin/bash

source ./yaml.sh

config_file="./config.yml"
if [[ ! -f "$config_file" ]]; then
  echo "cannot find config.yml!" && exit 1
fi

# Execute
create_variables config.yml

# master_name_arr
master_name_arr=()

# master_ip_arr
master_ip_arr=()

# worker_name_arr
worker_name_arr=()

# worker_ip_arr
worker_ip_arr=()

# etcd_name_arr
etcd_name_arr=()

# etcd_ip_arr
etcd_ip_arr=()

parse_info()
{
    # parsing master info
    for i in ${k8s_master[*]}; do
        str="${i}"
        arr=(${str//=/ })
        if [ ! ${arr[0]} ] || [ ! ${arr[1]} ]; then
            echo "master in config.yml Parsing error!" && exit 1
        fi
        master_name_arr+=( ${arr[0]} )
        master_ip_arr+=( ${arr[1]} )
    done

    # parsing worker info
    for i in ${k8s_worker[*]}; do
        str="${i}"
        arr=(${str//=/ })
        if [ ! ${arr[0]} ] || [ ! ${arr[1]} ]; then
            echo "worker in config.yml Parsing error!" && exit 1
        fi
        worker_name_arr+=( ${arr[0]} )
        worker_ip_arr+=( ${arr[1]} )
    done

    # parsing etcd info
    for i in ${k8s_etcd[*]}; do
        str="${i}"
        arr=(${str//=/ })
        if [ ! ${arr[0]} ] || [ ! ${arr[1]} ]; then
            echo "etcd in config.yml Parsing error!" && exit 1
        fi
        etcd_name_arr+=( ${arr[0]} )
        etcd_ip_arr+=( ${arr[1]} )
    done

    echo "Parse config.yml success!"
    echo ""
    echo "current k8s version: "${k8s_version}
    echo ""
    echo "master info:"
    echo ${master_name_arr[*]}
    echo ${master_ip_arr[*]}
    echo ""
    echo "worker info:"
    echo ${worker_name_arr[*]}
    echo ${worker_ip_arr[*]}
    echo ""
    echo "etcd info:"
    echo ${etcd_name_arr[*]}
    echo ${etcd_ip_arr[*]}
}
