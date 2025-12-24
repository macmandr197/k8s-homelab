# Cluster Bootstrapping

After the underlying infrastructure is provisioned (via Terraform or Omni), several core components must be configured in a specific order to enable GitOps management via ArgoCD.

For a detailed explanation of how these waves are managed, see the [ArgoCD & GitOps](./docs/argocd.md) Architecture documentation.

## Bootstrap Order (Sync Waves)

This cluster utilizes ArgoCD Sync Waves to manage dependencies. Components are deployed in the following order of importance:

**Wave 0: Foundation**

* **Networking (Cilium):** Installed initially via Talos inline manifests to allow the cluster to boot.

* **Secrets (External Secrets / 1Password Connect):** Required to retrieve credentials for storage and otherservices.

**Wave 1: Storage**

* **Proxmox CSI Plugin:** Depends on networking being fully operational, and retrieving secrets from 1Password via the ESO.

* **Longhorn:** Depends on networking being fully operational

**Wave 2 and Beyond**

* Databases, Cert-Manager, and user-facing applications.

## Final Bootstrap Step

Once the foundation is laid, the entire cluster management is handed off to ArgoCD using the "App of Apps" pattern.

```bash
./scripts/bootstrap-argocd.sh
```

### 2.`docs/first-time-setup.md`

This document outlines the manual prerequisite steps required before deploying applications.
