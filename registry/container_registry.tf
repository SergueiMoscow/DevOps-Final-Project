# Сервисный аккаунт для Container Registry
resource "yandex_iam_service_account" "registry_sa" {
  name        = "cr-service-account"
  description = "Service account for Yandex Container Registry"
}

# Роль push/pull для сервисного аккаунта
resource "yandex_resourcemanager_folder_iam_binding" "registry_sa_role" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  members   = [
    "serviceAccount:${yandex_iam_service_account.registry_sa.id}"
  ]
}

# Создание Yandex Container Registry
resource "yandex_container_registry" "netology_app_registry" {
  name      = "netology-app-registry"
  folder_id = var.folder_id
}


# Вывод ID реестра
output "registry_id" {
  value = yandex_container_registry.netology_app_registry.id
}

# Вывод ID сервистного аккаунта
output "service_account_id" {
  value = yandex_iam_service_account.registry_sa.id
}
