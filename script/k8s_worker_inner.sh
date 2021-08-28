#!bin/bash

echo "部署kubernetes工作节点"
echo "每个节点上会部署kubelet、kube-proxy、container runtime、cni、nginx-proxy"
echo ""
echo "1、Container Runtime - Containerd"

VERSION=1.5.5
cd /root
# 解压缩
tar -xvf cri-containerd-cni-${VERSION}-linux-amd64.tar.gz

# 复制需要的文件
cp etc/crictl.yaml /etc/
cp etc/systemd/system/containerd.service /etc/systemd/system/
cp -r usr /

mkdir -p /etc/containerd
# 默认配置生成配置文件
containerd config default > /etc/containerd/config.toml
# 修改为阿里云镜像
sed -i "s#k8s.gcr.io#registry.cn-hangzhou.aliyuncs.com/google_containers#g"  /etc/containerd/config.toml 
sed -i "s#https://registry-1.docker.io#https://registry.cn-hangzhou.aliyuncs.com#g"  /etc/containerd/config.toml
# 添加 SystemdCgroup = true
sed -i '/containerd.runtimes.runc.options/a\ \ \ \ \ \ \ \ \ \ \ \ SystemdCgroup = true' /etc/containerd/config.toml

# 启动containerd
systemctl enable containerd
systemctl restart containerd
# 检查状态
systemctl status containerd

echo "2、配置kubelet"

# 准备kubelet配置
mkdir -p /etc/kubernetes/ssl/
mv ${HOSTNAME}-key.pem ${HOSTNAME}.pem ca.pem ca-key.pem /etc/kubernetes/ssl/
mv ${HOSTNAME}.kubeconfig /etc/kubernetes/kubeconfig

# 本机ip
IP=$(hostname -I|awk '{print $1}')

# 写入kubelet配置文件
cat <<EOF > /etc/kubernetes/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/etc/kubernetes/ssl/ca.pem"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "169.254.25.10"
podCIDR: "10.200.0.0/16"
address: ${IP}
readOnlyPort: 0
staticPodPath: /etc/kubernetes/manifests
healthzPort: 10248
healthzBindAddress: 127.0.0.1
kubeletCgroups: /systemd/system.slice
resolvConf: "/etc/resolv.conf"
runtimeRequestTimeout: "15m"
kubeReserved:
  cpu: 200m
  memory: 512M
tlsCertFile: "/etc/kubernetes/ssl/${HOSTNAME}.pem"
tlsPrivateKeyFile: "/etc/kubernetes/ssl/${HOSTNAME}-key.pem"
EOF

# 配置kubelet服务
cat <<EOF > /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/etc/kubernetes/kubelet-config.yaml \\
  --container-runtime=remote \\
  --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/etc/kubernetes/kubeconfig \\
  --network-plugin=cni \\
  --node-ip=${IP} \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "3、配置nginx-proxy"

# nginx配置文件
mkdir -p /etc/nginx

# 执行前请先copy一份，并修改好upstream的 'server' 部分配置
cat <<EOF > /etc/nginx/nginx.conf
error_log stderr notice;

worker_processes 2;
worker_rlimit_nofile 130048;
worker_shutdown_timeout 10s;

events {
  multi_accept on;
  use epoll;
  worker_connections 16384;
}

stream {
  upstream kube_apiserver {
    least_conn;
    ${1}
  }

  server {
    listen        127.0.0.1:6443;
    proxy_pass    kube_apiserver;
    proxy_timeout 10m;
    proxy_connect_timeout 1s;
  }
}

http {
  aio threads;
  aio_write on;
  tcp_nopush on;
  tcp_nodelay on;

  keepalive_timeout 5m;
  keepalive_requests 100;
  reset_timedout_connection on;
  server_tokens off;
  autoindex off;

  server {
    listen 8081;
    location /healthz {
      access_log off;
      return 200;
    }
    location /stub_status {
      stub_status on;
      access_log off;
    }
  }
}
EOF

# nginx manifest
mkdir -p /etc/kubernetes/manifests/
cat <<EOF > /etc/kubernetes/manifests/nginx-proxy.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-proxy
  namespace: kube-system
  labels:
    addonmanager.kubernetes.io/mode: Reconcile
    k8s-app: kube-nginx
spec:
  hostNetwork: true
  dnsPolicy: ClusterFirstWithHostNet
  nodeSelector:
    kubernetes.io/os: linux
  priorityClassName: system-node-critical
  containers:
  - name: nginx-proxy
    image: docker.io/library/nginx:1.19
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        cpu: 25m
        memory: 32M
    securityContext:
      privileged: true
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8081
    readinessProbe:
      httpGet:
        path: /healthz
        port: 8081
    volumeMounts:
    - mountPath: /etc/nginx
      name: etc-nginx
      readOnly: true
  volumes:
  - name: etc-nginx
    hostPath:
      path: /etc/nginx
EOF

echo "4、配置kube-proxy"

mv kube-proxy.kubeconfig /etc/kubernetes/
# 创建 kube-proxy-config.yaml
cat <<EOF > /etc/kubernetes/kube-proxy-config.yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
bindAddress: 0.0.0.0
clientConnection:
  kubeconfig: "/etc/kubernetes/kube-proxy.kubeconfig"
clusterCIDR: "10.200.0.0/16"
mode: ipvs
EOF
# kube-proxy 服务文件
cat <<EOF > /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/etc/kubernetes/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "5、启动服务"
systemctl daemon-reload
systemctl enable kubelet kube-proxy
systemctl restart kubelet kube-proxy
journalctl -f -u kubelet
journalctl -f -u kube-proxy

echo "6、手动下载pause镜像"
crictl pull registry.cn-hangzhou.aliyuncs.com/kubernetes-kubespray/pause:3.2
ctr -n k8s.io i tag  registry.cn-hangzhou.aliyuncs.com/kubernetes-kubespray/pause:3.2 k8s.gcr.io/pause:3.2








