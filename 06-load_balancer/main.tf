# load-balancer/main.tf
data "terraform_remote_state" "infra" {
  # https://yandex.cloud/ru/docs/storage/tutorials/terraform-state-storage
  backend = "s3"
  config = {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = var.bucket_name
    key    = "infra.tfstate"
    region = "ru-central1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true

    access_key = var.sa_access_key
    secret_key = var.sa_secret_key
  }
}

locals {
  subnet_zones = data.terraform_remote_state.infra.outputs.subnet_zones
  worker_ips = data.terraform_remote_state.infra.outputs.worker_internal_ips
  subnet_ids = data.terraform_remote_state.infra.outputs.subnet_ids
}

resource "yandex_lb_target_group" "netology_tg" {
  name = "netology-target-group"
  
  dynamic "target" {
    for_each = { for idx, ip in local.worker_ips : idx => ip }
    
    content {
      subnet_id  = local.subnet_ids[local.subnet_zones[target.key + 1]]  # +1 т.к. worker-ноды начинаются с индекса 1
      address    = target.value
    }
  }
}
