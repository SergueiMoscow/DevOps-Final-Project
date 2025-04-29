# Security Group для Kubernetes
resource "yandex_vpc_security_group" "k8s_sg" {
  name        = "k8s-security-group"
  network_id  = yandex_vpc_network.netology.id
  description = "Security group for Kubernetes cluster"

  ingress {
    protocol       = "TCP"
    description    = "Allow SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow NodePort services"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  ingress {
    protocol       = "ANY"
    description    = "Allow internal communication"
    v4_cidr_blocks = ["10.10.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Копируем существующий SSH-ключ в infra для Ansible
resource "local_file" "ssh_private_key" {
  content  = file("~/.ssh/id_ed25519")
  filename = "${path.module}/id_ed25519"
}

data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2204-lts"
}


# ВМ для control plane
resource "yandex_compute_instance" "k8s_control_plane" {
  name        = "k8s-control-plane"
  zone        = var.subnet_zone[0]  # ru-central1-a
  platform_id = "standard-v3"
  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 20
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_zones[0].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
  }
  metadata = local.vm_metadata
}

# ВМ для worker nodes
resource "yandex_compute_instance" "k8s_worker" {
  count       = 2
  name        = "k8s-worker-${count.index}"
  zone        = var.subnet_zone[count.index + 1]  # ru-central1-b, ru-central1-d
  platform_id = "standard-v3"
  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_image.id
      size     = 10
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet_zones[count.index + 1].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
  }
  metadata = local.vm_metadata
  scheduling_policy {
    preemptible = true  # Прерываемая ВМ
  }
}

# Генерация inventory для Kubespray
resource "local_file" "kubespray_inventory" {
  content = templatefile("${path.module}/templates/inventory.tftpl", {
    control_plane_ip = yandex_compute_instance.k8s_control_plane.network_interface[0].nat_ip_address
    worker_ip_0      = yandex_compute_instance.k8s_worker[0].network_interface[0].nat_ip_address
    worker_ip_1      = yandex_compute_instance.k8s_worker[1].network_interface[0].nat_ip_address
  })
  filename = local.inventory_file
}

# Вывод IP-адресов (для отладки)
output "control_plane_ip" {
  value = yandex_compute_instance.k8s_control_plane.network_interface[0].nat_ip_address
}

output "worker_ips" {
  value = [for instance in yandex_compute_instance.k8s_worker : instance.network_interface[0].nat_ip_address]
}
