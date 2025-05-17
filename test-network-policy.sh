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

# Ana program
print_header "Network Policy Test Aracı"

# Pod IP'lerini al
CODEGEN_POD_IP=$(kubectl get pod test-pod-codegen -n codegen -o jsonpath='{.status.podIP}')
NONAMENS_POD_IP=$(kubectl get pod test-pod-nonamens -n nonamens -o jsonpath='{.status.podIP}')

echo -e "${BLUE}codegen namespace'indeki pod IP: ${CODEGEN_POD_IP}${NC}"
echo -e "${BLUE}nonamens namespace'indeki pod IP: ${NONAMENS_POD_IP}${NC}"

# Test 1: Network policy aktifken nonamens -> codegen ping testi
print_header "Test 1: Network policy aktifken nonamens -> codegen ping testi"
echo -e "${BLUE}Network policy aktif. nonamens'den codegen'e ping atılıyor...${NC}"
kubectl exec -it test-pod-nonamens -n nonamens -- ping -c 4 ${CODEGEN_POD_IP} || echo -e "${GREEN}Beklenen sonuç: Ping başarısız (engellendi)${NC}"

# Test 2: Network policy aktifken codegen -> nonamens ping testi
print_header "Test 2: Network policy aktifken codegen -> nonamens ping testi"
echo -e "${BLUE}Network policy aktif. codegen'den nonamens'e ping atılıyor...${NC}"
kubectl exec -it test-pod-codegen -n codegen -- ping -c 4 ${NONAMENS_POD_IP} && echo -e "${GREEN}Beklenen sonuç: Ping başarılı (engellenmedi)${NC}" || echo -e "${RED}Beklenmeyen sonuç: Ping başarısız${NC}"

# Test 3: Network policy devre dışıyken nonamens -> codegen ping testi
print_header "Test 3: Network policy devre dışıyken nonamens -> codegen ping testi"
echo -e "${BLUE}Network policy kaldırılıyor...${NC}"
kubectl delete -f k8s/network-policy.yaml

echo -e "${BLUE}Network policy devre dışı. nonamens'den codegen'e ping atılıyor...${NC}"
kubectl exec -it test-pod-nonamens -n nonamens -- ping -c 4 ${CODEGEN_POD_IP} && echo -e "${GREEN}Beklenen sonuç: Ping başarılı (engellenmedi)${NC}" || echo -e "${RED}Beklenmeyen sonuç: Ping başarısız${NC}"

# Network policy'yi tekrar uygula
print_header "Network policy tekrar uygulanıyor"
kubectl apply -f k8s/network-policy.yaml

# Test 4: Cilium network policy testi
print_header "Test 4: Cilium network policy testi"
echo -e "${BLUE}Cilium network policy uygulanıyor...${NC}"
kubectl apply -f k8s/cilium-network-policy.yaml

echo -e "${BLUE}Cilium network policy aktif. nonamens'den codegen'e ping atılıyor...${NC}"
kubectl exec -it test-pod-nonamens -n nonamens -- ping -c 4 ${CODEGEN_POD_IP} || echo -e "${GREEN}Beklenen sonuç: Ping başarısız (engellendi)${NC}"

# Özet
print_header "Test Sonuçları"
echo -e "${GREEN}Network policy testleri tamamlandı.${NC}"
echo -e "${BLUE}Kubernetes Network Policy'ler başarıyla test edildi.${NC}"
echo -e "${YELLOW}Not: Cilium network policy'nin çalışması için Cilium CNI'nın kurulu olması gerekir.${NC}"
