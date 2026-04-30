resource "proxmox_virtual_environment_vm" "talos" {
  for_each = var.talos_nodes

  name      = each.value.name
  node_name = var.proxmox_node_name
  vm_id     = each.value.vm_id

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_dedicated
  }

  network_device {
    bridge = var.proxmox_network_bridge
  }

  disk {
    datastore_id = var.proxmox_datastore_id
    interface    = "virtio0"
    size         = each.value.disk_size
    file_format  = "raw"
  }

  cdrom {
    enabled = true
    file_id = var.talos_iso_file_id
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.proxmox_datastore_id
    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = each.value.gateway
      }
    }
  }
}
