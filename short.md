cd 01-sa_bucket
terraform apply

cd ../02-infra
./init_backend.sh
terraform apply

# Генерируем JSON с output в корне проекта:
terraform output -json > ../infra-outputs.json

cd ../04-k8s
./deploy_k8s.sh

kubectl get pods --all-namespaces

cd ../05-k8s-manifests/monitoring
kubectl apply --server-side -f manifests/setup
kubectl wait \
	--for condition=Established \
	--all CustomResourceDefinition \
	--namespace=monitoring

kubectl apply -f manifests

kubectl get pods -n monitoring

# Версия с Yandex Load Balancer
cd ../../06-load_balancer
./init_backend.sh

# Версия с MetalLB:
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# Создание секрета для деплоя приложения
kubectl create secret docker-registry yandex-registry-secret \
  --docker-server=cr.yandex \
  --docker-username=json_key \
  --docker-password="$(cat ../../03-registry/registry_sa_key.json)" \
  -n default

# Деплой приложения
cd ..
kubectl apply -f app/deployment.yaml
kubectl apply -f app/service.yaml
kubectl apply -f app/ingress.yaml

# Ingress для grafana:
kubectl apply -f monitoring/grafana-ingress.yaml

# Генерируем metallb-config:
```bash
./generate-metallb-config.sh
```

# Config metallb
kubectl apply -f metallb/metallb-config.yaml

# Делегируем домен
https://admin.yandex.ru/domains/sushkovs.ru?action=set_dns&uid=85832025

# Проверяем
dig netology2.sushkovs.ru +short