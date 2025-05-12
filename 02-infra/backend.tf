# terraform init \
#   -backend-config="bucket=bucket_name" \
#   -backend-config="access_key=access_key" \
#   -backend-config="secret_key=secret_key"


terraform {
  backend "s3" {
    bucket   = var.bucket_name
    key      = "infra.tfstate"
    region   = "ru-central1"
    endpoints.s3 = "https://storage.yandexcloud.net"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
  }
}
