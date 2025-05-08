# terraform init \
#   -backend-config="bucket=bucket_name" \
#   -backend-config="access_key=access_key" \
#   -backend-config="secret_key=secret_key"


terraform {
  backend "s3" {
    bucket   = var.bucket_name
    key      = "load-balancer.tfstate"
    region   = "ru-central1-a"
    endpoint = "https://storage.yandexcloud.net"
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
  }
}
