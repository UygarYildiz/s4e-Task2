#!/bin/bash

# Renk tanımlamaları
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonksiyonlar
print_header() {
    echo -e "\n${YELLOW}$1${NC}"
    echo -e "${YELLOW}$(printf '=%.0s' $(seq 1 ${#1}))${NC}\n"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}$1 bulunamadı. Lütfen yükleyin.${NC}"
        return 1
    else
        echo -e "${GREEN}$1 kurulu.${NC}"
        return 0
    fi
}

# Ana program
print_header "Kubernetes Network Policies Projesi Kurulum Aracı"

# Gerekli araçları kontrol et
print_header "Gerekli araçlar kontrol ediliyor"
check_docker=$(check_command docker)
check_kubectl=$(check_command kubectl)
check_kind=$(check_command kind)
check_helm=$(check_command helm)

if [ $? -ne 0 ]; then
    echo -e "${RED}Lütfen eksik araçları yükleyin ve tekrar deneyin.${NC}"
    exit 1
fi

# Kubernetes cluster oluştur
print_header "Kubernetes cluster oluşturuluyor"
kind create cluster --config=kind-config.yaml
if [ $? -ne 0 ]; then
    echo -e "${RED}Cluster oluşturma başarısız oldu.${NC}"
    exit 1
fi

# Cluster durumunu kontrol et
print_header "Cluster durumu kontrol ediliyor"
kubectl get nodes
kubectl cluster-info

# Namespace'leri oluştur
print_header "Namespace'ler oluşturuluyor"
kubectl apply -f k8s/namespaces.yaml
kubectl apply -f k8s/resource-limits.yaml

# Ingress controller kur
print_header "Ingress controller kuruluyor"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
echo -e "${BLUE}Ingress controller hazır olana kadar bekleniyor...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Cilium kur
print_header "Cilium kuruluyor"
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --namespace kube-system

# ArgoCD kur
print_header "ArgoCD kuruluyor"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo -e "${BLUE}ArgoCD hazır olana kadar bekleniyor...${NC}"
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=120s

# Kyverno kur
print_header "Kyverno kuruluyor"
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.10.0/install.yaml
echo -e "${BLUE}Kyverno hazır olana kadar bekleniyor...${NC}"
kubectl wait --namespace kyverno \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=kyverno \
  --timeout=120s

# Monitoring stack kur
print_header "Monitoring stack kuruluyor"
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -f k8s/monitoring/prometheus-values.yaml --namespace monitoring
helm install loki grafana/loki-stack -f k8s/monitoring/loki-values.yaml --namespace monitoring

# Uygulamaları deploy et
print_header "Uygulamalar deploy ediliyor"
kubectl apply -f k8s/nonamens-app.yaml
helm install codegen-app ./helm/codegen --namespace codegen

# Network policy uygula
print_header "Network policy uygulanıyor"
kubectl apply -f k8s/network-policy.yaml

# Kyverno policy'leri uygula
print_header "Kyverno policy'leri uygulanıyor"
kubectl apply -f k8s/security/kyverno-policies.yaml

# Test pod'larını oluştur
print_header "Test pod'ları oluşturuluyor"
kubectl apply -f k8s/test-pods.yaml

# Kurulum tamamlandı
print_header "Kurulum tamamlandı"
echo -e "${GREEN}Kubernetes Network Policies projesi başarıyla kuruldu!${NC}"
echo -e "${BLUE}Uygulamalara erişmek için:${NC}"
echo -e "  ArgoCD: http://localhost:8080 (kubectl port-forward svc/argocd-server -n argocd 8080:443)"
echo -e "  Grafana: http://localhost:3000 (kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80)"
echo -e "  AI Code Generator: http://localhost (kubectl port-forward svc/codegen-app -n codegen 80:80)"
echo -e "${YELLOW}Network policy'yi test etmek için:${NC}"
echo -e "  kubectl exec -it test-pod-nonamens -n nonamens -- ping \$(kubectl get pod test-pod-codegen -n codegen -o jsonpath='{.status.podIP}')"
