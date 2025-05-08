output "sa_id" {
  value = yandex_iam_service_account.sa.id
}

output "bucket_name" {
  value = yandex_storage_bucket.s3_bucket.bucket
}

output "sa_access_key" {
  value     = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  sensitive = true
}

output "sa_secret_key" {
  value     = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  sensitive = true
}

output "folder_id" {
  value = var.folder_id
}