resource "yandex_vpc_network" "netology" {
  name = var.vpc_name
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "k8s-nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "k8s_route_table" {
  name       = "k8s-route-table"
  network_id = yandex_vpc_network.netology.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "subnet_zones" {
  count          = 3
  name           = "subnet-${var.subnet_zones[count.index]}"
  zone           = var.subnet_zones[count.index]
  network_id     = yandex_vpc_network.netology.id
  v4_cidr_blocks = [var.cidr[count.index]]
  route_table_id = yandex_vpc_route_table.k8s_route_table.id # Привязываем таблицу маршрутизации
}


output "subnet_ids" {
  value = {
    for idx, subnet in yandex_vpc_subnet.subnet_zones :
    subnet.zone => subnet.id
  }
}

output "subnet_zones" {
  value       = var.subnet_zones
  description = "Список зон доступности, используемых для подсетей"
}