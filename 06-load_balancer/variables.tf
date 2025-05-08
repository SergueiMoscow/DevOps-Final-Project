variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

variable "tfstate_key" {
  type = string
  default = "load-balancer.tfstate"
  description = "Ключ в бакете, содержащий tfstate текущей директории"
}

variable "bucket_name" {
  type = string
}

variable "sa_access_key" {
  type        = string
  sensitive   = true
  description = "Static access key for Yandex Cloud Service Account. Передавать через переменную (export)"
}

variable "sa_secret_key" {
  type        = string
  sensitive   = true
  description = "Static secret key for Yandex Cloud Service Account. Передавать через переменную (export)"
}