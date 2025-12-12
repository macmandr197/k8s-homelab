resource "proxmox_virtual_environment_vm" "talos_control_plane" {
  for_each    = local.control_plane_nodes
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = local.node_name
  on_boot     = true

  cpu {
    cores = each.value.config.cpu.cores
    type  = each.value.config.cpu.type
  }

  memory {
    dedicated = each.value.config.memory_in_MiB
  }

  agent {
    enabled = local.agent_enabled
  }

  network_device {
    bridge = each.value.config.network_device.bridge
  }

  disk {
    datastore_id = each.value.config.disk.datastore_id
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format  = each.value.config.disk.file_format
    interface    = each.value.config.disk.interface
    size         = each.value.config.disk.size
  }

  operating_system {
    type = local.operating_system
  }

  initialization {
    datastore_id = local.datastore_id
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = local.default_gateway
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  for_each    = local.worker_nodes
  depends_on  = [proxmox_virtual_environment_vm.talos_control_plane]
  name        = each.key
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = local.node_name
  on_boot     = true

  cpu {
    cores = each.value.config.cpu.cores
    type  = each.value.config.cpu.type
  }

  memory {
    dedicated = each.value.config.memory_in_MiB
  }

  agent {
    enabled = local.agent_enabled
  }

  network_device {
    bridge = each.value.config.network_device.bridge
  }

  disk {
    datastore_id = each.value.config.disk.datastore_id
    file_id      = each.value.gpu_enabled ? proxmox_virtual_environment_download_file.talos_nocloud_gpu_enabled.id : proxmox_virtual_environment_download_file.talos_nocloud_standard.id
    file_format  = each.value.config.disk.file_format
    interface    = each.value.config.disk.interface
    size         = each.value.config.disk.size
  }

  operating_system {
    type = local.operating_system
  }

  # uses mapped GPU named "nvidia-gpu".
  dynamic "hostpci" {
    for_each = each.value.gpu_enabled ? [1] : []
    content {
      device  = "hostpci0"
      mapping = "nvidia-gpu" 
      pcie    = true
      rombar  = true
      xvga    = false 
    }
  }

  initialization {
    datastore_id = local.datastore_id
    ip_config {
      ipv4 {
        address = "${each.value.ip_address}/24"
        gateway = local.default_gateway
      }
    }
  }
}