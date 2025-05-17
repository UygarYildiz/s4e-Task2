#!/bin/bash

# Kubernetes sürümü
K8S_VERSION=$1

# Master node'u başlat
kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16 --kubernetes-version=${K8S_VERSION}

# kubeconfig dosyasını ayarla
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Root kullanıcısı için de kubeconfig ayarla
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Calico CNI'yı kur
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Worker node'lar için join komutu oluştur
kubeadm token create --print-join-command > /home/vagrant/join.sh
chmod +x /home/vagrant/join.sh
