#!/bin/bash

function phase1() {
swapoff -a
sed -i '/swap/s/^/#/g' /etc/fstab
firewall-cmd --list-ports
iptables -P FORWARD ACCEPT
firewall-cmd --add-masquerade --permanent
firewall-cmd --add-port=10250/tcp --permanent
firewall-cmd --add-port=8472/udp --permanent
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10257/tcp
firewall-cmd --permanent --add-port=10259/tcp

#firewall-cmd --permanent --add-port=30000-32767/tcp   # NodePort Range (work node only)
systemctl restart firewalld
firewall-cmd --list-ports

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
lsmod | grep br_netfilter
lsmod | grep overlay

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
stat -fc %T /sys/fs/cgroup/
grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"
touch .init_install
reboot
}

function phase2() {

KUBERNETES_VERSION=v1.32
CRIO_VERSION=v1.32

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/rpm/repodata/repomd.xml.key
EOF

cat <<EOF | tee /etc/yum.repos.d/cri-o.repo
[cri-o]
name=CRI-O
baseurl=https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/rpm/repodata/repomd.xml.key
EOF

dnf install -y container-selinux
dnf install -y cri-o kubelet kubeadm kubectl
systemctl start crio.service

echo "[crio.image]" > /etc/crio/crio.conf.d/20-crio.conf 
echo 'pause_image="registry.k8s.io/pause:3.10"' >> /etc/crio/crio.conf.d/20-crio.conf
systemctl reload crio
rm .init_install
#ifconfig ens34:0 inet 192.168.10.99 netmask 255.255.255.0
#ifconfig ens34:0 up
}

if [ ! -f .init_install ]; then
    phase1
else
    phase2
fi
