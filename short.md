cd sa_bucket
terraform apply

cd ../infra
./init_backend.sh
terraform apply

cd ../k8s
./deploy_k8s.sh

kubectl get pods --all-namespaces

cd ../k8s-manifests/monitoring
kubectl apply --server-side -f manifests/setup
kubectl apply -f manifests

kubectl get pods -n monitoring