resource "yandex_vpc_network" "netology" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "subnet_zones" {
  count          = 3
  name           = "subnet-${var.subnet_zone[count.index]}"
  zone           = "${var.subnet_zone[count.index]}"
  network_id     = "${yandex_vpc_network.netology.id}"
  v4_cidr_blocks = [ "${var.cidr[count.index]}" ]
}
