locals {
  talos = {
    version = "v1.11.5"
  }
  kubeVersion = "1.34.2"

  base_extensions = ["nfsd", "qemu-guest-agent"]
  gpu_extensions  = ["nonfree-kmod-nvidia-production", "nvidia-container-toolkit-production"]
}

data "talos_image_factory_extensions_versions" "standard" {
  # get the latest talos version
  talos_version = local.talos.version
  filters = {
    names = local.base_extensions
  }
}

data "talos_image_factory_extensions_versions" "gpu_enabled" {
  # get the latest talos version
  talos_version = local.talos.version
  filters = {
    names = concat(local.base_extensions, local.gpu_extensions)
  }
}

resource "talos_image_factory_schematic" "standard" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.standard.extensions_info.*.name
        }
      }
    }
  )
}

resource "talos_image_factory_schematic" "gpu_enabled" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.gpu_enabled.extensions_info.*.name
        }
      }
    }
  )
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud_standard" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "proxmox"

  file_name               = "talos-${local.talos.version}-standard-amd64.img"
  url                     = "https://factory.talos.dev/image/${resource.talos_image_factory_schematic.standard.id}/${local.talos.version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}

resource "proxmox_virtual_environment_download_file" "talos_nocloud_gpu_enabled" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "proxmox"

  file_name               = "talos-${local.talos.version}-gpu_enabled-amd64.img"
  url                     = "https://factory.talos.dev/image/${resource.talos_image_factory_schematic.gpu_enabled.id}/${local.talos.version}/nocloud-amd64.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}