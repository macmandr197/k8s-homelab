resource "talos_machine_secrets" "machine_secrets" {}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = local.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints            = [for node in values(local.control_plane_nodes) : node.ip_address]
}

data "talos_machine_configuration" "machineconfig_cp" {
  for_each         = local.control_plane_nodes
  cluster_name     = local.cluster_name
  cluster_endpoint = "https://${local.cluster_endpoint}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets

  config_patches = [
    # [cite_start]Patch 1: Replaces cluster.tftpl [cite: 128]
    yamlencode({
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
        apiServer = {
          certSANs = ["labber.mcmn.me"]
        }
        inlineManifests = [
          {
            name = "cilium"
            # This directly injects the manifest string, and yamlencode
            # handles the correct YAML literal block formatting.
            contents = data.helm_template.cilium_template.manifest
          }
        ]
      }
    }),

    # [cite_start]Patch 2: Replaces machine.tftpl [cite: 130]
    yamlencode({
      machine = {
        install = {
          extraKernelArgs = ["net.ifnames=0"]
        }
        network = {
          nameservers = ["1.1.1.1", "8.8.8.8"]
          interfaces = [
            {
              interface = "eth0"
              vip = {
                ip = local.cluster_endpoint
              }
            }
          ]
        }
        features = {
          hostDNS = {
            enabled              = true
            forwardKubeDNSToHost = false # uses host upstream resolvers to avoid issue with passing link-local cache from node to pod
          }
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  for_each                    = local.control_plane_nodes
  depends_on                  = [proxmox_virtual_environment_vm.talos_control_plane]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp[each.key].machine_configuration
  node                        = each.value.ip_address
}

data "talos_machine_configuration" "machineconfig_worker" {
  for_each         = local.worker_nodes
  cluster_name     = local.cluster_name
  cluster_endpoint = "https://${local.cluster_endpoint}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets

  config_patches = concat(
    # Apply standard machine config to all nodes
    [
    yamlencode({
      machine = {
        network = {
          nameservers = ["1.1.1.1", "8.8.8.8"]
        }
        features = {
          hostDNS = {
            enabled              = true
            forwardKubeDNSToHost = false # uses host upstream resolvers to avoid issue with passing link-local cache from node to pod
          }
        }
      }
    })
  ],
  # Only GPU-enabled nodes
  each.value.gpu_enabled ? [
    yamlencode({
      machine = {
        kernel = {
          modules = [
            { name = "nvidia" },
            { name = "nvidia_uvm" },
            { name = "nvidia_drm" },
            { name = "nvidia_modeset" }
          ]
        }
      }
    })
  ] : [] #apply nothing if the machine is not gpu_enabled
  )
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  for_each                    = local.worker_nodes
  depends_on                  = [proxmox_virtual_environment_vm.talos_worker]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker[each.key].machine_configuration
  node                        = each.value.ip_address
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.cp_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = values(local.control_plane_nodes)[0].ip_address
}

data "talos_cluster_health" "health" {
  depends_on           = [talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes  = [for node in values(local.control_plane_nodes) : node.ip_address]
  worker_nodes         = [for node in values(local.worker_nodes) : node.ip_address]
  endpoints            = data.talos_client_configuration.talosconfig.endpoints
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = values(local.control_plane_nodes)[0].ip_address
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = resource.talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}