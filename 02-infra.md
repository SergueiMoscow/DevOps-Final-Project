## Создание инфраструктуры для Kubernetes
### Подготовка создания инфраструктуры

В директории `02-infra` создаём скрипт [init_backend.sh](02-infra/init_backend.sh), который:
- Переходит в директорию `01-sa_bucket`.
- Получает значения `sa_access_key`, `sa_secret_key` и `bucket_name` из outputs.
- Инициализирует Terraform с S3-бэкендом, используя эти значения.

Запуск скрипта:
```bash
./init_backend.sh
```
Это автоматизирует настройку бэкенда, исключая ручной ввод ключей.

В файле [network.tf](02-infra/network.tf) создаём:
- VPC (`my_network`).
- Три подсети в зонах `ru-central1-a`, `ru-central1-b`, `ru-central1-d` с CIDR-блоками `10.10.1.0/24`, `10.10.2.0/24`, `10.10.3.0/24`.  

Зоны и CIDR-блоки определены в переменных в [variables.tf](02-infra/variables.tf)

В файле [backend.tf](02-infra/backend.tf) настраиваем S3-бэкенд для хранения состояния `terraform.tfstate` в бакете, созданном в `01-sa_bucket`.


Для подтягивания ключей доступа к серверам подтягиваем существующий `ed_25519.pub` публичный ключ в [locals.tf](02-infra/locals.tf)

Создаём [k8s_nodes.tf](02-infra/k8s_nodes.tf)

### Подготовка для последующей установки kubernetes
Создаём директорию для [04-k8s](04-k8s) для `ansible-playbook`.

Переходим в неё и колнируем `kubespray`
```
git clone https://github.com/kubernetes-sigs/kubespray
```

Создаём `inventory` и копируем туда пример конфигурации
```
cd kubespray
mkdir -p inventory/mycluster
cp -r inventory/sample/group_vars inventory/mycluster/
```

Создаём [deploy_k8s.sh](04-k8s/deploy_k8s.sh) и даём права на выполнение
```
chmod +x deploy_k8s.sh
```

### Запуск
В директории `02-infra` выполняем:
```bash
./init_backend.sh  # Инициализация бэкенда вместо terraform init с подтягиванием ключей
terraform validate
terraform plan
terraform apply
```

Генерируем JSON с output в корне проекта для следующих этапов:
```bash
terraform output -json > ../infra-outputs.json
```
