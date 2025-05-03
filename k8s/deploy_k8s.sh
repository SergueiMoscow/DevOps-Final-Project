#!/bin/bash
set -e

# Получение IP control plane
control_plane_ip=$(terraform -chdir=../infra output -raw control_plane_ip)
if [ -z "$control_plane_ip" ]; then
  echo "Error: control_plane_ip is empty. Check Terraform output."
  exit 1
fi
echo "Control plane IP: $control_plane_ip"

# Настройка Yandex Cloud Controller Manager
echo "Configuring Yandex Cloud Controller Manager..."
cat << EOF > kubespray/inventory/mycluster/group_vars/all/yandex.yml
yandex_cloud_controller_manager:
  folder_id: "$(terraform -chdir=../sa_bucket output -raw folder_id)"
  service_account_key_file: "/etc/yandex-cloud/sa-key.json"
EOF
sed -i '/cloud_provider:/ s/.*/cloud_provider: yandex/' kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml
sed -i '/yandex_cloud_controller_enabled:/ s/.*/yandex_cloud_controller_enabled: true/' kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

# Копирование ключа сервисного аккаунта на ноды
echo "Copying service account key to nodes..."
access_key=$(terraform -chdir=../sa_bucket output -raw sa_access_key)
secret_key=$(terraform -chdir=../sa_bucket output -raw sa_secret_key)
cat << EOF > sa-key.json
{
  "access_key": "$access_key",
  "secret_key": "$secret_key"
}
EOF
for ip in $(terraform -chdir=../infra output -json worker_ips | jq -r '.[]' && echo $control_plane_ip); do
  ssh -i ../infra/id_ed25519 ubuntu@$ip "sudo mkdir -p /etc/yandex-cloud && sudo chown ubuntu:ubuntu /etc/yandex-cloud"
  scp -i ../infra/id_ed25519 sa-key.json ubuntu@$ip:/etc/yandex-cloud/sa-key.json
done
rm sa-key.json

# Настройка NGINX Ingress Controller
echo "Configuring NGINX Ingress Controller..."
sed -i 's/ingress_nginx_enabled: false/ingress_nginx_enabled: true/' kubespray/inventory/mycluster/group_vars/k8s_cluster/addons.yml
sed -i 's/# ingress_nginx_service_type: LoadBalancer/ingress_nginx_service_type: LoadBalancer/' kubespray/inventory/mycluster/group_vars/k8s_cluster/addons.yml

# Настройка supplementary_addresses_in_ssl_keys
echo "Configuring Kubernetes SSL keys..."
sed -i "/supplementary_addresses_in_ssl_keys:/ s#.*#supplementary_addresses_in_ssl_keys: [\"${control_plane_ip}\"]#" kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

# Проверка inventory
echo "Verifying inventory..."
cat kubespray/inventory/mycluster/inventory.ini

echo "Deploying Kubernetes with Kubespray..."
cd kubespray
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml --become --flush-cache

echo "Copying kubeconfig..."
ssh -i ../infra/id_ed25519 ubuntu@$control_plane_ip "mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown ubuntu:ubuntu ~/.kube/config"

scp -i ../infra/id_ed25519 ubuntu@$control_plane_ip:/home/ubuntu/.kube/config ~/.kube/config
sed -i "s/127.0.0.1/$control_plane_ip/" ~/.kube/config

echo "Checking cluster..."
kubectl get pods --all-namespaces

echo "Checking NGINX Ingress Controller..."
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
