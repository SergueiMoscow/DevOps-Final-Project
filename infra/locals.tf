locals {
  vm_metadata = {
    serial-port-enable = 1
    ssh-keys           = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
  inventory_file = "${path.module}/../k8s/kubespray/inventory/mycluster/inventory.ini"
}