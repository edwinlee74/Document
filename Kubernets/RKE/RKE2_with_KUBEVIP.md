# RKE2 With kube-VIP 安裝

### 可參考Nutanix官網的安裝方法
[Deploy Highly Available RKE2 with Kube-VIP](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2103-Rancher-SUSE-Nutanix:deploy-highly-available-rke2-with-kube-vip.html)

### 以root 身份進行安裝
```shell
sudo su -
```
### 建立環境變數
```shell
export RKE2_API_VIP=<API_SERVER_VIP_IP>
export RKE2_NODE_0_IP=<CONTROL_PLANE_FIRST_NODE_IP>
export RKE2_NODE_1_IP=<CONTROL_PLANE_SECOND_NODE_IP>
export RKE2_NODE_2_IP=<CONTROL_PLANE_THIRD_NODE_IP>
export NODE_JOIN_TOKEN=`echo "$(uuidgen)::$(openssl rand -hex 16)"`
export INTERFACE=enp0s3
export KUBE_VIP_VERSION=v0.4.2
```

### 建立RKE2 所需目錄 
```shell
mkdir -p /etc/rancher/rke2
mkdir -p /var/lib/rancher/rke2/server/manifests/
```
### 建立Rancher RKE2 config.yaml (可以所需環境設定disable選項)
```shell
cat <<EOF | tee /etc/rancher/rke2/config.yaml
token: ${NODE_JOIN_TOKEN}
tls-san:
- ${HOSTNAME}
- ${RKE2_API_VIP}
- ${RKE2_NODE_0_IP}
- ${RKE2_NODE_1_IP}
- ${RKE2_NODE_2_IP}
write-kubeconfig-mode: 600
etcd-expose-metrics: true
cni:
- calico
disable:
- rke2-ingress-nginx
- rke2-snapshot-validation-webhook
- rke2-snapshot-controller
- rke2-snapshot-controller-crd
EOF
```
### 指定安裝版本:
```shell
   ## script會檢查環境, 如不能用RPM安裝,會下載tar ball。
   curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.28.15+rke2r1 sh -
```

### 啟用RKE2 服務
```shell
systemctl enable rke2-server.service
systemctl start rke2-server.service
```
### 查看log是否已啟用成功
```shell
journalctl -u rke2-server -f
```
### 檢查NODE是否已經Ready
```shell
export PATH=$PATH:/var/lib/rancher/rke2/bin
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export CONTAINER_RUNTIME_ENDPOINT=unix:///run/k3s/containerd/containerd.sock
export CONTAINERD_ADDRESS=/run/k3s/containerd/containerd.sock

kubectl get nodes -o wide
```
### 建立kube-vip的RBAC清單
```shell
curl https://kube-vip.io/manifests/rbac.yaml > /var/lib/rancher/rke2/server/manifests/kube-vip-rbac.yaml
```

### 抓取kube-vip image和設定別名
```shell
crictl pull docker.io/plndr/kube-vip:$KUBE_VIP_VERSION

alias kube-vip="ctr --namespace k8s.io run --rm --net-host docker.io/plndr/kube-vip:$KUBE_VIP_VERSION vip /kube-vip"

```

### 建立Kube-VIP Daemonset static pod manifests
```shell
kube-vip manifest daemonset \
    --interface $INTERFACE \
    --address $RKE2_API_VIP \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection | tee /var/lib/rancher/rke2/server/manifests/kube-vip.yaml
```

### 檢查kube-vip是否已部署成功
```shell
kubectl get ds -n kube-system kube-vip-ds
```

### 在其餘二台NODE重覆上述動作, 除了config.yaml再多新增server選項
```shell
cat <<EOF | tee /etc/rancher/rke2/config.yaml
server: https://${RKE2_API_VIP}:9345
token: ${NODE_JOIN_TOKEN}
tls-san:
- ${HOSTNAME}
- ${RKE2_API_VIP}
- ${RKE2_NODE_0_IP}
- ${RKE2_NODE_1_IP}
- ${RKE2_NODE_2_IP}
write-kubeconfig-mode: 600
etcd-expose-metrics: true
cni:
- calico
disable:
- rke2-ingress-nginx
- rke2-snapshot-validation-webhook
- rke2-snapshot-controller
- rke2-snapshot-controller-crd
EOF
```