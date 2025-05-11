## Создание CI/CD для инфраструктуры
Создаём секреты в GitHub Actions:
1. YC_SERVICE_ACCOUNT_KEY с json содержимым фала ключа.
2. TF_VARS с содержимым файла main.auto.tfvars

![Secrets](images/image24.png)

Создаём [workflow](.github/workflows/terraform.yml)
