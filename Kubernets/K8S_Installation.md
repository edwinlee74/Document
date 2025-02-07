# Kubernets 安裝

## OS: Oracle linux 8.10

**swap off**
```shell
# swapoff -a

***編輯/etc/fstab,並註解掉swap.img使其重開機後不會再掛載swap 分割區***

# vim /etc/fstab   
註釋掉swap不讓系統自動掛載
```

**設定 firewall以及iptables**
```shell
### 查看已開放port

# firewall-cmd --list-ports

### Master 節點（控制平面）
# iptables -P FORWARD ACCEPT
# firewall-cmd --add-masquerade --permanent
# firewall-cmd --add-port=10250/tcp --permanent // Kubelet API
# firewall-cmd --add-port=8472/udp --permanent
# firewall-cmd --permanent --add-port=6443/tcp   // API Server
# firewall-cmd --permanent --add-port=2379-2380/tcp  // etcd 
# firewall-cmd --permanent --add-port=10257/tcp  // kube-controller-manager
# firewall-cmd --permanent --add-port=10259/tcp  // kube-scheduler

### Worker 節點
# firewall-cmd --permanent --add-port=10250/tcp  // Kubelet
# firewall-cmd --permanent --add-port=30000-32767/tcp  // NodePort Services


### 重啟firewalld服務
# systemctl restart firewalld
```
**安裝Container Runtime**
```shell
### 安裝前需要轉發IPv4並讓iptables能看到橋接流量
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# modprobe overlay
# modprobe br_netfilter

### 啟用ipv4 封包轉發
### 設置所需的sysctl參數, 參數在重啟後保持不變

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
  
### 重啟system

# sysctl --system

### 確認overlay、br_netfilter模組已經載入且運行

lsmod | grep br_netfilter
lsmod | grep overlay

### 確認net.bridge.bridge-nf-call-iptables、net.bridge.bridge-nf-call-ip6tables、net.ipv4.ip_forward的值已經改為1

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

### 將SELinux設置permissive模式(相當於禁用)

# setenforce 0
# sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

### 如果你的Linux是以systemd作為初始化系統時, 不建議使用cgroupfs, 或是使用cgrop v2都應使用systemd cgroup driver來取代cgroupfs。 確認你的linux環境使用那一種cgroup driver:
### 以pstree確認是否為systemd

# pstree  

### 確認你的cgroup是否為cgroup v2
### tmpfs 為cgroup v1
### cgroup2fs 為cgroup v2

# stat -fc %T /sys/fs/cgroup/

### 如果不是cgroup v2以下列方法設定

grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"

### 重開機後生效

# reboot

### CRI-O runtime
### 指定版本

KUBERNETES_VERSION=v1.32
CRIO_VERSION=v1.32

### 加入Kubernets repository

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF

### 加入CRI-O repository

cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key
EOF

### 安裝相依套件

# dnf install -y container-selinux

### 安裝套件

# dnf install -y cri-o kubelet kubeadm kubectl

### 啟用CRIO

# systemctl start crio.service

### 

# vi /etc/crio/crio.conf.d/20-crio.conf 
[crio.image]
pause_image="registry.k8s.io/pause:3.10"

### 重啟服務

# systemctl reload crio

```

**初始化master節點**
control-plane節點是運作etcd、apiserver的機器, 以kubeadm init <args>來初始化。
* 如果master節點有作HA, 可加入--control-plane-endpoint作為所有master共享端點。
* 依所選取的overlayer network設定--pod-network-cidr, 例如選Calico: 192.168.0.0/16
* 另外還有--cri-socket這個選項, 基本上如你有安裝CRI了會自動偵測, 不用設定。

```shell
kubeadm init --apiserver-advertise-address=192.168.10.222 --pod-network-cidr=10.244.0.0/16
```
### 以一般user身份執行下列指令
```shell
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config

### 記錄剛kubeadm init產生的最後訊息, NODE加入cluster就是使用它來加入
```
### 安裝pod 網路附加組件
```shell
### 下載canal設定清單

#curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/canal.yaml -O

### 開始安裝
# kubectl apply -f canal.yaml

```
**加入節點**
```shell
### 登入各台工作節點, 並以root身份登入, 將剛剛kubeadm init最後那一行複制貼上
kubeadm join 192.168.10.222:6443 --token qhmojd.pf3yspy6jpab7lcw \
        --discovery-token-ca-cert-hash sha256:fb0bce5ca96cfe5c377b4eb49000b0a14b61ef9725d740ae4ce8f5715f40e562

### 由於預設工作節點的ROLES為NONE,所以要為工作節點打上角色標籤
kubectl label nodes evan-kub-node1 kubernetes.io/role=worker

### 查看Node是否已經加入
kubectl get nodes
```