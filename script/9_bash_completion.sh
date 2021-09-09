#!bin/bash

echo "Install bash_completion"

# Load the content of the parsed configuration file
source "./parse.sh"

# Exceute
parse_info

# master nodes
for instance in ${master_name_arr[@]}; do
    ssh -o StrictHostKeyChecking=no root@${instance} "bash -s" < bash_completion_inner.sh
done

echo "success!" && exit 0
