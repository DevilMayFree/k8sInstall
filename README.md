# k8sInstall
shell script for  kubernetes-the-hard-way 

kubernetes version: v1.22

**please run all shell script on the one of your master nodes**

**the version should run on centos7**

how to use

1、set your master node info, worker node info and etcd node info on ```config.yml```

2、upload all script files to the root directory, on your master node ,such as k8s-master-1
   
3、run ```~/script/ssh_key.sh``` , it will generate id_rsa.pub and send to all node
   and set hosts

4、run scripts in order
>  ```00_remote_update_kernel.sh``` will update_kernel and reboot the machine but exclude self, 
  so you should run ```0_update_kernel.sh``` on current machine. 

>  ```01_remote_init_env.sh``` will init your environment but exclude self,
  so you should run ```1_init_env.sh``` on current machine.

enjoy it
