#!/bin/bash
set -e

echo "Copying kubeconfig..."
control_plane_ip=$(terraform -chdir=../infra output -raw control_plane_ip)

echo "Deploying Kubernetes with Kubespray..."
sed -i "/supplementary_addresses_in_ssl_keys:/ s/.*/supplementary_addresses_in_ssl_keys: [\"$control_plane_ip\"]/" kubespray/inventory/mycluster/group_vars/k8s_cluster/k8s-cluster.yml

cd kubespray
ansible-playbook -i inventory/mycluster/inventory.ini cluster.yml --become

echo "Copying kubeconfig..."
control_plane_ip=$(terraform -chdir=../../infra output -raw control_plane_ip)
ssh -i ../../infra/id_ed25519 ubuntu@$control_plane_ip "mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown ubuntu:ubuntu ~/.kube/config"

scp -i ../../infra/id_ed25519 ubuntu@$control_plane_ip:/home/ubuntu/.kube/config ~/.kube/config
sed -i "s/127.0.0.1/$control_plane_ip/" ~/.kube/config

echo "Checking cluster..."
kubectl get pods --all-namespaces
