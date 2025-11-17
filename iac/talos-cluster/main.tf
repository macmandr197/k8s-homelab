provider "proxmox" {
  endpoint = "https://proxmox.mcmn.io:8006/"
  #insecure = true # Only needed if your Proxmox server is using a self-signed certificate
}