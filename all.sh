#!/bin/bash
set -e # Автоматически завершать скрипт при ошибке

# Функция для проверки успешности выполнения команды
check_command() {
  if [ $? -ne 0 ]; then
    echo "❌ Ошибка при выполнении: $1"
    exit 1
  else
    echo "✅ Успешно: $1"
  fi
}

# 1. Развертывание инфраструктуры
echo "🚀 Этап 1: Развертывание инфраструктуры в Yandex Cloud"
cd 02-infra
./init_backend.sh
terraform apply -auto-approve
check_command "terraform apply"

# Генерируем JSON с output
echo "📝 Генерация outputs.json"
terraform output -json > ../infra-outputs.json
check_command "Создание infra-outputs.json"

# Получаем IP адреса
CONTROL_IP=$(jq -r '.control_plane_ip.value' ../infra-outputs.json)
WORKER_IPS=$(jq -r '.worker_ips.value[]' ../infra-outputs.json)

# # 2. Настройка DNS (если установлен YC CLI)
# echo "🌐 Этап 2: Настройка DNS (если доступен YC CLI)"
# if command -v yc &> /dev/null; then
#   echo "Обновляем DNS запись для netology2.sushkovs.ru..."
#   yc dns zone add-records --name sushkovs.ru --record "netology2 60 A $CONTROL_IP"
#   for ip in $WORKER_IPS; do
#     yc dns zone add-records --name sushkovs.ru --record "netology2 60 A $ip"
#   done
#   echo "DNS записи добавлены. Ожидаем распространение DNS (1-2 минуты)..."
#   sleep 120
# else
#   echo "⚠️ YC CLI не установлен. Необходимо вручную добавить DNS записи:"
#   echo "Домен: netology2.sushkovs.ru"
#   echo "IP адреса:"
#   echo "- $CONTROL_IP (control plane)"
#   for ip in $WORKER_IPS; do
#     echo "- $ip (worker)"
#   done
# fi

# 3. Установка Kubernetes
echo "⚙️ Этап 3: Установка Kubernetes кластера"
cd ../04-k8s
./deploy_k8s.sh
check_command "Установка Kubernetes"

# Ждем доступности API сервера
echo "⏳ Ожидаем доступности Kubernetes API..."
API_READY=0
for i in {1..30}; do
  if kubectl get nodes &> /dev/null; then
    API_READY=1
    break
  fi
  sleep 10
  echo "Попытка $i/30: API сервер недоступен..."
done

if [ $API_READY -eq 0 ]; then
  echo "❌ Kubernetes API недоступен после 5 минут ожидания"
  exit 1
fi

# 4. Настройка MetalLB
echo "🔌 Этап 4: Настройка MetalLB"
cd ../05-k8s-manifests

echo "Настройка strictARP..."
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
check_command "Настройка strictARP"

echo "Установка MetalLB..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml
check_command "Установка MetalLB"

# Ждем готовности MetalLB
echo "⏳ Ожидаем запуска MetalLB..."
# kubectl wait --for=condition=ready pod -l app=metallb -n metallb-system --timeout=180s
kubectl wait --for=condition=ready pod --all -n metallb-system --timeout=180s
check_command "MetalLB готов"

# Генерация и применение конфигурации MetalLB
echo "Генерация конфигурации MetalLB..."
./generate-metallb-config.sh
check_command "Генерация metallb-config.yaml"

echo "Применение конфигурации MetalLB..."
kubectl apply -f metallb/metallb-config.yaml
check_command "Применение MetalLB конфига"

# 5. Настройка Ingress
echo "🌐 Этап 5: Настройка Ingress"
kubectl apply -f ingress/ingress-nginx-networkpolicy.yaml
check_command "Применение NetworkPolicy для ingress-nginx"

# 6. Настройка registry secret
echo "🔑 Этап 6: Создание секрета для Docker registry"
kubectl create secret docker-registry yandex-registry-secret \
  --docker-server=cr.yandex \
  --docker-username=json_key \
  --docker-password="$(cat ../03-registry/registry_sa_key.json)" \
  -n default
check_command "Создание registry secret"

# 7. Развертывание приложения
echo "🚀 Этап 7: Развертывание приложения"
kubectl apply -f app/deployment.yaml
kubectl apply -f app/service.yaml
kubectl apply -f app/ingress.yaml
check_command "Развертывание приложения"

# 8. Установка мониторинга
echo "📊 Этап 8: Установка системы мониторинга"
kubectl apply --server-side -f monitoring/manifests/setup
check_command "Установка kube-prometheus (setup)"

echo "Ожидаем готовности CRDs..."
kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring --timeout=180s
check_command "CRDs готовы"

kubectl apply -f monitoring/manifests/
check_command "Установка kube-prometheus"

# 9. Настройка Grafana
echo "📈 Этап 9: Настройка Grafana"
kubectl patch deployment -n monitoring grafana --patch-file monitoring/grafana-deployment-patch.yaml
check_command "Настройка Grafana через patch"

kubectl apply -f monitoring/grafana-ingress.yaml
check_command "Настройка Ingress для Grafana"

kubectl apply -f monitoring/grafana-networkpolicy.yaml
check_command "Настройка NetworkPolicy для Grafana"

# Проверка доступности
echo "🔍 Проверка доступности приложений..."
echo "Приложение должно быть доступно по: http://netology2.sushkovs.ru"
echo "Grafana должна быть доступна по: http://netology2.sushkovs.ru/grafana"

# Возвращаемся в корень проекта
cd ..

echo "🎉 Все компоненты успешно развернуты!"
