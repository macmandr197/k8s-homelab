terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    proxmox = {
      source  = "bpg/proxmox"
      version = "0.89.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
  }
  backend "s3" {
    endpoints = {
      s3 = "https://s3.ca-east-006.backblazeb2.com"
    }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    region                      = "us-east-1" #any value
    bucket                      = "mcmn-iac"
    key                         = "terraform.tfstate"
  }
}