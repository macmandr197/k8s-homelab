locals {
  # --- 1. Global Settings ---
  # Variables that apply to the whole cluster
  cluster_endpoint = "172.16.8.10"
  cluster_name     = "labber"
  default_gateway  = "172.16.8.1"
  datastore_id     = "pool-1"
  operating_system = "l26" # Linux Kernel 2.6 - 5.X.
  node_name        = "proxmox"
  agent_enabled    = true

  # --- 2. Control Plane: Shared Config ---
  # Common settings for ALL control plane nodes
  control_plane_shared_config = {
    cpu = {
      cores = 2
      type  = "x86-64-v2-AES"
    }
    memory_in_MiB = 4096
    network_device = {
      bridge = "infra"
    }
    disk = {
      datastore_id = local.datastore_id # Reference the global setting
      file_format  = "raw"
      interface    = "virtio0"
      size         = 50
    }
  }

  # --- 3. Control Plane: Node-Specific Data ---
  # A map where the KEY is the hostname and the VALUE is a map of unique settings
  control_plane_node_data = {
    "talos-cp-01" = { ip_address = "172.16.8.11" }
    "talos-cp-02" = { ip_address = "172.16.8.12" }
    "talos-cp-03" = { ip_address = "172.16.8.13" }
  }

  # --- 4. Worker Nodes: Shared Config ---
  # Common settings for ALL worker nodes
  worker_node_shared_config = {
    cpu = {
      cores = 4
      type  = "x86-64-v2-AES"
    }
    memory_in_MiB = 4096
    network_device = {
      bridge = "infra"
    }
    disk = {
      datastore_id = local.datastore_id # Reference the global setting
      file_format  = "raw"
      interface    = "virtio0"
      size         = 100
    }
  }

  # --- 5. Worker Nodes: Node-Specific Data ---
  # A map where the KEY is the hostname and the VALUE is a map of unique settings
  worker_node_data = {
    "talos-wk-01" = { ip_address = "172.16.8.14" }
    "talos-wk-02" = { ip_address = "172.16.8.15" }
    "talos-wk-03" = { 
      ip_address  = "172.16.8.16"
      gpu_enabled = true
      }
  }

  # --- 6. Final Maps for for_each ---
  # These loops build the final maps your resources will iterate over.
  # They combine the shared config with the node-specific data.

  control_plane_nodes = {
    # 'hostname' will be "talos-cp-01", etc.
    # 'node_data' will be { ip_address = "..." }
    for hostname, node_data in local.control_plane_node_data : hostname => {
      # We merge everything into one convenient object
      hostname   = hostname
      ip_address = node_data.ip_address
      config     = local.control_plane_shared_config
    }
  }

  worker_nodes = {
    for hostname, node_data in local.worker_node_data : hostname => {
      hostname   = hostname
      ip_address = node_data.ip_address
      config     = local.worker_node_shared_config
      gpu        = try(node_data.gpu_enabled, false)
    }
  }
}