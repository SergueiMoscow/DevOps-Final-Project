resource "yandex_lb_network_load_balancer" "netology_lb" {
  name = "netology-devops-app-lb"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.netology_tg.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 30518  # NodePort сервиса
        path = "/"    # Проверяем корень приложения
      }
    }
  }
}

output "load_balancer_ip" {
  value = flatten(yandex_lb_network_load_balancer.netology_lb.listener[*].external_address_spec[*].address)[0]
  description = "Внешний IP балансировщика"
}

