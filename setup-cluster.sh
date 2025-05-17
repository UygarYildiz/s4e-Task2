#!/bin/bash

# Renk tanımlamaları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonksiyonlar
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}$1 bulunamadı. Lütfen yükleyin.${NC}"
        return 1
    else
        echo -e "${GREEN}$1 kurulu.${NC}"
        return 0
    fi
}

install_kind() {
    echo -e "${BLUE}Kind yükleniyor...${NC}"
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    echo -e "${GREEN}Kind başarıyla yüklendi.${NC}"
}

install_k3d() {
    echo -e "${BLUE}K3d yükleniyor...${NC}"
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo -e "${GREEN}K3d başarıyla yüklendi.${NC}"
}

install_kubectl() {
    echo -e "${BLUE}kubectl yükleniyor...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/windows/amd64/kubectl.exe"
    chmod +x kubectl.exe
    mv kubectl.exe /usr/local/bin/kubectl
    echo -e "${GREEN}kubectl başarıyla yüklendi.${NC}"
}

create_kind_cluster() {
    echo -e "${BLUE}Kind cluster oluşturuluyor...${NC}"
    kind create cluster --config=kind-config.yaml
    echo -e "${GREEN}Kind cluster başarıyla oluşturuldu.${NC}"
}

create_k3d_cluster() {
    echo -e "${BLUE}K3d cluster oluşturuluyor...${NC}"
    k3d cluster create --config k3d-config.yaml
    echo -e "${GREEN}K3d cluster başarıyla oluşturuldu.${NC}"
}

# Ana program
echo -e "${YELLOW}Kubernetes Cluster Kurulum Aracı${NC}"
echo -e "${YELLOW}=================================${NC}"

# Gerekli araçları kontrol et
echo -e "${BLUE}Gerekli araçlar kontrol ediliyor...${NC}"
check_docker=$(check_command docker)
check_kubectl=$(check_command kubectl)
check_kind=$(check_command kind)
check_k3d=$(check_command k3d)

# Eksik araçları yükle
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Eksik araçlar yükleniyor...${NC}"
    
    if [ "$check_kubectl" == "1" ]; then
        install_kubectl
    fi
    
    if [ "$check_kind" == "1" ] && [ "$check_k3d" == "1" ]; then
        echo -e "${YELLOW}Hangi aracı kullanmak istersiniz? (kind/k3d)${NC}"
        read tool
        
        if [ "$tool" == "kind" ]; then
            install_kind
            tool_choice="kind"
        elif [ "$tool" == "k3d" ]; then
            install_k3d
            tool_choice="k3d"
        else
            echo -e "${RED}Geçersiz seçim. Çıkılıyor.${NC}"
            exit 1
        fi
    elif [ "$check_kind" == "1" ]; then
        tool_choice="k3d"
    elif [ "$check_k3d" == "1" ]; then
        tool_choice="kind"
    else
        echo -e "${YELLOW}Hangi aracı kullanmak istersiniz? (kind/k3d)${NC}"
        read tool_choice
    fi
else
    echo -e "${YELLOW}Hangi aracı kullanmak istersiniz? (kind/k3d)${NC}"
    read tool_choice
fi

# Cluster oluştur
if [ "$tool_choice" == "kind" ]; then
    create_kind_cluster
elif [ "$tool_choice" == "k3d" ]; then
    create_k3d_cluster
else
    echo -e "${RED}Geçersiz seçim. Çıkılıyor.${NC}"
    exit 1
fi

# Cluster durumunu kontrol et
echo -e "${BLUE}Cluster durumu kontrol ediliyor...${NC}"
kubectl get nodes
kubectl cluster-info

echo -e "${GREEN}Kubernetes cluster kurulumu tamamlandı!${NC}"
