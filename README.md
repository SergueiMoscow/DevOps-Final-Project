[Задание](https://github.com/netology-code/devops-diplom-yandexcloud)

## Создание облачной инфраструктуры

### Требования для запуска
- Установленный Terraform (версия ≥ 1.5).
- Доступ к Яндекс.Облаку с файлом ключей `~/.yc_authorized_key.json`.
- Настроенные переменные по примерам из [01-sa_bucket](01-sa_bucket/auto.tfvars.example) и [02-infra](02-infra/auto.tfvars.example) в файлах `<filename>.auto.tfvars`.
- Приватный и публичный ключи `id_ed25519` в `~/.ssh/`

### Подготовка

Для управления инфраструктурой создаём две отдельные директории:
- **[01-sa_bucket](01-sa_bucket)**: Для создания сервисного аккаунта и S3-бакета, используемого как бэкенд для хранения состояния Terraform.
- **[02-infra](02-infra)**: Для создания основной инфраструктуры (VPC и подсетей).
- **[03-registry](03-registry)**: Для создания контенера и публикации его в Yandex Registry.
- **[04-k8s](04-k8s)**: Установка kubernetes на виртуальных машинах.
- **[05-k8s-manifests](05-k8s-manifests)**: Для манифестов Kubernetes.

### Этапы
#### 1. [Подготовка бакета](01-sa_bucket.md)
**Важно** После этапа 1 обновить секреты GitHub `YC_S3_ACCESS_KEY` и `YC_S3_SECRET_KEY` в репозитории этого проекта.
#### 2. [Создание инфраструктуры](02-infra.md)
#### 3. [Cоздание контейнера и публикация его в Yandex Registry](03-registry.md)
**Важно** После этапа 3 обновить секрет GitHub `REGISTRY_ID` в репозитории с приложением.
#### 4. [Установка kubernetes на виртуальных машинах](04-k8s.md)
**Важно** После этого этапа обновить секрет GitHub `KUBE_CONFIG` в репозитории с приложением.
#### 5. [Установка приложения и мониторинга через манифесты Kubernetes](05-k8s-manifests.md)
#### 6. [Создание CI/CD для изменения инфраструктуры](06-cicd-infra.md)
#### 7. [Создание CI/CD для изменения приложения](07-cicd-app.md)

---

Для развёртывания всей инфраструктуры с установкой приложения и мониторинга одной комадной можно использовать [all.sh](all.sh). При этом в облаке должны уже должны быть
- Созданы сервисный аккаунт и S3-бакет, используемый как бекенд для хранения состояния Terraform. ([шаг 1](01-sa_bucket.md))
- Создан контейнер и опубликован в Yandex Registry. ([шаг 3](03-registry.md))
