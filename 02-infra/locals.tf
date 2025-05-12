locals {
  vm_metadata = {
    serial-port-enable = 1
    ssh-keys           = "ubuntu:${var.ssh_public_key}"
  }
  inventory_file = "${path.module}/../04-k8s/kubespray/inventory/mycluster/inventory.ini"
}
