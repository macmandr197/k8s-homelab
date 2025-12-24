### 4. `docs/omni-bootstrapping.md`

This document details the Omni-specific workflow for cluster management.

# Omni-Based Bootstrapping

For more dynamic or self-hosted management, this cluster has the option of being deployed via [Sidero Omni](https://www.siderolabs.com/platform/sidero-omni/).

## Infrastructure & Hosting

* **Hosting:** Both the Omni instance and the Proxmox provider for Omni are hosted on a separate management server.
* **Certificates:** SSL termination and certificate management are handled by an Nginx reverse proxy.
* **Node Lifecycle:** The cluster utilizes the Proxmox provider for Omni to handle automated node creation and deletion.

## DNS & SideroLink Requirements

Omni-based clusters require nodes to resolve the Omni endpoint (`omni.mcmn.io`) for SideroLink to function.
* **DNS Record:** A record for `omni.mcmn.io` is created within the cloud gateway.

* **DNS Overrides:** Node-class patches are used to override default DNS providers, pointing them to the infra VLAN gateway (`172.16.8.1`) and `8.8.8.8`. The gateway utilizes `1.1.1.1` as its upstream provider.
* **Note:** This manual DNS configuration is specific to Omni; Terraform-based deployments handle this during node creation.

## Manual Hardware Requirements

* **GPU Nodes:** Until explicitly supported by the Proxmox provider, you must manually attach the PCI GPU resource to a GPU-enabled node in the Proxmox UI to allow it to boot correctly with GPU extensions.
* **Static IPs:** To ensure nodes retain static IP addresses, you must create a DHCP reservation for each node after Omni creates the VM. These are are store within the Unifi Cloud Gateway Fiber.

## Setup Instructions

### 1. Create Machine Classes

Machine classes define the VM specifications (CPU, RAM, Disk) and are applied using the `omnictl` CLI tool.

`omnictl apply -f iac/omni/machine-classes/{...}.yaml`

### 2. Deploy the Cluster with Omni

The cluster is deployed using the cluster template in `iac/omni/cluster-template/cluster-template.yaml`.

It can be deployed using the following command: `omnictl cluster template sync -v -f iac/omni/cluster-template/cluster-template.yaml`

