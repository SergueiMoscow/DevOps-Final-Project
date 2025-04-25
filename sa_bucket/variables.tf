variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
  # default     = "b1gs3dkkmirep8agd6af"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
  # default     = "b1gnqq5a1oat2u6dk42u"
}

variable "bucket_name" {
  type = string
  # default = "sushkov-2025-04-24"
}

variable "default_zone" {
  type        = string
  # default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
