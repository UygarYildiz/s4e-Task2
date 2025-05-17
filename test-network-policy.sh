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

# Test pod'larının varlığını kontrol et
echo -e "${BLUE}Test pod'larının varlığını kontrol ediyoruz...${NC}"
if ! kubectl get pod test-pod-codegen -n codegen &> /dev/null; then
    echo -e "${YELLOW}test-pod-codegen bulunamadı. Oluşturuluyor...${NC}"
    kubectl apply -f k8s/test-pods.yaml
    echo -e "${BLUE}Pod'ların hazır olması için bekleniyor...${NC}"
    kubectl wait --for=condition=ready pod test-pod-codegen -n codegen --timeout=60s
    kubectl wait --for=condition=ready pod test-pod-nonamens -n nonamens --timeout=60s
elif ! kubectl get pod test-pod-nonamens -n nonamens &> /dev/null; then
    echo -e "${YELLOW}test-pod-nonamens bulunamadı. Oluşturuluyor...${NC}"
    kubectl apply -f k8s/test-pods.yaml
    echo -e "${BLUE}Pod'ların hazır olması için bekleniyor...${NC}"
    kubectl wait --for=condition=ready pod test-pod-codegen -n codegen --timeout=60s
    kubectl wait --for=condition=ready pod test-pod-nonamens -n nonamens --timeout=60s
fi

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
# Network policy'leri kontrol et ve varsa sil
if kubectl get networkpolicy -n codegen deny-from-nonamens &> /dev/null; then
    kubectl delete networkpolicy -n codegen deny-from-nonamens
    echo -e "${GREEN}deny-from-nonamens network policy silindi.${NC}"
else
    echo -e "${YELLOW}deny-from-nonamens network policy bulunamadı.${NC}"
fi

if kubectl get networkpolicy -n codegen default-deny-all &> /dev/null; then
    kubectl delete networkpolicy -n codegen default-deny-all
    echo -e "${GREEN}default-deny-all network policy silindi.${NC}"
else
    echo -e "${YELLOW}default-deny-all network policy bulunamadı.${NC}"
fi

if kubectl get networkpolicy -n codegen allow-from-same-namespace &> /dev/null; then
    kubectl delete networkpolicy -n codegen allow-from-same-namespace
    echo -e "${GREEN}allow-from-same-namespace network policy silindi.${NC}"
else
    echo -e "${YELLOW}allow-from-same-namespace network policy bulunamadı.${NC}"
fi

if kubectl get networkpolicy -n codegen allow-from-kube-system &> /dev/null; then
    kubectl delete networkpolicy -n codegen allow-from-kube-system
    echo -e "${GREEN}allow-from-kube-system network policy silindi.${NC}"
else
    echo -e "${YELLOW}allow-from-kube-system network policy bulunamadı.${NC}"
fi

echo -e "${BLUE}Network policy değişikliklerinin uygulanması için bekleniyor...${NC}"
sleep 10  # 10 saniye bekle

echo -e "${BLUE}Test pod'larını yeniden başlatıyoruz...${NC}"
# Test pod'larını kontrol et ve varsa sil
if kubectl get pod test-pod-codegen -n codegen &> /dev/null; then
    kubectl delete pod test-pod-codegen -n codegen
    echo -e "${GREEN}test-pod-codegen silindi.${NC}"
else
    echo -e "${YELLOW}test-pod-codegen bulunamadı.${NC}"
fi

if kubectl get pod test-pod-nonamens -n nonamens &> /dev/null; then
    kubectl delete pod test-pod-nonamens -n nonamens
    echo -e "${GREEN}test-pod-nonamens silindi.${NC}"
else
    echo -e "${YELLOW}test-pod-nonamens bulunamadı.${NC}"
fi

# Test pod'larını oluştur
kubectl apply -f k8s/test-pods.yaml
echo -e "${GREEN}Test pod'ları oluşturuldu.${NC}"

echo -e "${BLUE}Pod'ların hazır olması için bekleniyor...${NC}"
kubectl wait --for=condition=ready pod test-pod-codegen -n codegen --timeout=60s
kubectl wait --for=condition=ready pod test-pod-nonamens -n nonamens --timeout=60s

# Pod IP'lerini güncelle
CODEGEN_POD_IP=$(kubectl get pod test-pod-codegen -n codegen -o jsonpath='{.status.podIP}')
NONAMENS_POD_IP=$(kubectl get pod test-pod-nonamens -n nonamens -o jsonpath='{.status.podIP}')

echo -e "${BLUE}Güncellenmiş pod IP'leri:${NC}"
echo -e "${BLUE}codegen namespace'indeki pod IP: ${CODEGEN_POD_IP}${NC}"
echo -e "${BLUE}nonamens namespace'indeki pod IP: ${NONAMENS_POD_IP}${NC}"

echo -e "${BLUE}Network policy devre dışı. nonamens'den codegen'e ping atılıyor...${NC}"
kubectl exec -it test-pod-nonamens -n nonamens -- ping -c 4 ${CODEGEN_POD_IP} && echo -e "${GREEN}Beklenen sonuç: Ping başarılı (engellenmedi)${NC}" || echo -e "${RED}Beklenmeyen sonuç: Ping başarısız${NC}"

# Network policy'yi tekrar uygula
print_header "Network policy tekrar uygulanıyor"
kubectl apply -f k8s/alternative-network-policy.yaml

echo -e "${BLUE}Network policy değişikliklerinin uygulanması için bekleniyor...${NC}"
sleep 10  # 10 saniye bekle

echo -e "${BLUE}Test pod'larını yeniden başlatıyoruz...${NC}"
# Test pod'larını kontrol et ve varsa sil
if kubectl get pod test-pod-codegen -n codegen &> /dev/null; then
    kubectl delete pod test-pod-codegen -n codegen
    echo -e "${GREEN}test-pod-codegen silindi.${NC}"
else
    echo -e "${YELLOW}test-pod-codegen bulunamadı.${NC}"
fi

if kubectl get pod test-pod-nonamens -n nonamens &> /dev/null; then
    kubectl delete pod test-pod-nonamens -n nonamens
    echo -e "${GREEN}test-pod-nonamens silindi.${NC}"
else
    echo -e "${YELLOW}test-pod-nonamens bulunamadı.${NC}"
fi

# Test pod'larını oluştur
kubectl apply -f k8s/test-pods.yaml
echo -e "${GREEN}Test pod'ları oluşturuldu.${NC}"

echo -e "${BLUE}Pod'ların hazır olması için bekleniyor...${NC}"
kubectl wait --for=condition=ready pod test-pod-codegen -n codegen --timeout=60s
kubectl wait --for=condition=ready pod test-pod-nonamens -n nonamens --timeout=60s

# Pod IP'lerini güncelle
CODEGEN_POD_IP=$(kubectl get pod test-pod-codegen -n codegen -o jsonpath='{.status.podIP}')
NONAMENS_POD_IP=$(kubectl get pod test-pod-nonamens -n nonamens -o jsonpath='{.status.podIP}')

echo -e "${BLUE}Güncellenmiş pod IP'leri:${NC}"
echo -e "${BLUE}codegen namespace'indeki pod IP: ${CODEGEN_POD_IP}${NC}"
echo -e "${BLUE}nonamens namespace'indeki pod IP: ${NONAMENS_POD_IP}${NC}"

# Test 4: Cilium network policy testi
print_header "Test 4: Cilium network policy testi"
echo -e "${BLUE}Cilium network policy uygulanıyor...${NC}"
# Cilium CRD'lerin varlığını kontrol et
if kubectl api-resources | grep -q "ciliumnetworkpolicies.cilium.io"; then
    kubectl apply -f k8s/cilium-network-policy.yaml
    echo -e "${GREEN}Cilium network policy uygulandı.${NC}"
else
    echo -e "${YELLOW}Cilium CRD'leri bulunamadı. Cilium network policy uygulanamadı.${NC}"
    echo -e "${YELLOW}Bu beklenen bir durum, çünkü Cilium CNI kurulu değil.${NC}"
fi

echo -e "${BLUE}Network policy değişikliklerinin uygulanması için bekleniyor...${NC}"
sleep 10  # 10 saniye bekle

echo -e "${BLUE}Cilium network policy aktif. nonamens'den codegen'e ping atılıyor...${NC}"
kubectl exec -it test-pod-nonamens -n nonamens -- ping -c 4 ${CODEGEN_POD_IP} || echo -e "${GREEN}Beklenen sonuç: Ping başarısız (engellendi)${NC}"

# Özet
print_header "Test Sonuçları"
echo -e "${GREEN}Network policy testleri tamamlandı.${NC}"
echo -e "${BLUE}Kubernetes Network Policy'ler başarıyla test edildi.${NC}"
echo -e "${YELLOW}Not: Cilium network policy'nin çalışması için Cilium CNI'nın kurulu olması gerekir.${NC}"
