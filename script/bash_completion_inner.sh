#!bin/bash

echo "Install bash_completion"

# run type _init_completion
type _init_completion
# if it failed. add this into ~./bashrc
# source /usr/share/bash-completion/bash_completion
echo 'source /usr/share/bash-completion/bash_completion' >>~/.bashrc

# reload shell
echo 'source <(kubectl completion bash)' >>~/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl

# alias
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -F __start_kubectl k' >>~/.bashrc

echo "success!" && exit 0
