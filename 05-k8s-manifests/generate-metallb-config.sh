#!/bin/bash

# Получаем IP из Terraform output
# CONTROL_PLANE_IP=$(terraform -chdir=../02-infra output -raw control_plane_ip)
# WORKER_IP_0=$(terraform -chdir=../02-infra output -json worker_ips | jq -r '.[0]')
# WORKER_IP_1=$(terraform -chdir=../02-infra output -json worker_ips | jq -r '.[1]')

# Получаем IP из JSON
CONTROL_PLANE_IP=$(jq -r '.control_plane_ip.value' ../infra-outputs.json)
WORKER_IP_0=$(jq -r '.worker_ips.value[0]' ../infra-outputs.json)
WORKER_IP_1=$(jq -r '.worker_ips.value[1]' ../infra-outputs.json)

# Генерируем metallb-config.yaml
cat <<EOF > metallb/metallb-config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: yc-pool
  namespace: metallb-system
spec:
  addresses:
  - ${CONTROL_PLANE_IP}/32
  - ${WORKER_IP_0}/32
  - ${WORKER_IP_1}/32
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2adv
  namespace: metallb-system
spec:
  ipAddressPools:
  - yc-pool
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: metallb
  namespace: metallb-system
data:
  config: |
    address-pools:
    - name: yc-pool
      protocol: layer2
      addresses:
      - ${CONTROL_PLANE_IP}/32
EOF
echo "Generated metallb/metallb-config.yaml with IPs: ${CONTROL_PLANE_IP}, ${WORKER_IP_0}, ${WORKER_IP_1}"

# Генерируем netology-devops-app-service.yaml
cat <<EOF > app/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: netology-devops-app
  namespace: default
  annotations:
    metallb.io/ip-allocated-from-pool: yc-pool
  # Note: Using WORKER_IP_0 (${WORKER_IP_0}) for netology-devops-app LoadBalancer
spec:
  ports:
  - name: http
    port: 80
    targetPort: 80
    protocol: TCP
  selector:
    app: netology-devops-app
  type: LoadBalancer
  loadBalancerIP: ${WORKER_IP_0}
EOF
echo "Generated app/service.yaml with IP: ${WORKER_IP_0}"

# Обновляем ingress-nginx-service.yaml с новым loadBalancerIP
if [ -f ingress/ingress-nginx-service.yaml ]; then
  sed -i "s/loadBalancerIP: .*/loadBalancerIP: ${CONTROL_PLANE_IP}/" ingress/ingress-nginx-service.yaml
  echo "Updated ingress/ingress-nginx-service.yaml with IP: ${CONTROL_PLANE_IP}"
else
  echo "Error: ingress/ingress-nginx-service.yaml not found"
  exit 1
fi

# Обновляем app/service.yaml с новым loadBalancerIP
if [ -f ingress/ingress-nginx-service.yaml ]; then
  sed -i "s/loadBalancerIP: .*/loadBalancerIP: ${WORKER_IP_0}/" app/service.yaml
  echo "Updated app/service.yaml with IP: ${WORKER_IP_0}"
else
  echo "Error: app/service.yaml not found"
  exit 1
fi
