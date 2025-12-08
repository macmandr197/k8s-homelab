# Labber, a Kubernetes Cluster Built with Talos and ArgoCD, on Proxmox

configured cloud gateway fiber for BGP to use Cillium as my LB
router BGP ASN 65510
router id 172.16.72.10

peer remote-as 65512

all services will be advertised via BGP unless explicitly labeled with: cilium-lb-no-advertise=true

## Deploying Cluster With Terraform

**required** credentials needed to apply for terraform

Backblaze key for S2 backend
Promox API key for API functions
Proxmox SSH user / private key for SSH operations

## Preparation for First Time Cluster Deployment

These are steps required for applications deployed by Argo to succeed. Ie. populating secret data within 1Password.

### Cloudflare

You'll need to create two secrets for Cloudflare integration:

1. DNS API Token for cert-manager (DNS validation)
2. Tunnel credentials for cloudflared (Tunnel connectivity)

#### 1. DNS API Token

```bash
# REQUIRED BROWSER STEPS FIRST:
# Navigate to Cloudflare Dashboard:
# 1. Profile > API Tokens
# 2. Create Token
# 3. Use "Edit zone DNS" template
# 4. Configure permissions:
#    - Zone - DNS - Edit
#    - Zone - Zone - Read
# 5. Set zone resources to your domain
# 6. Copy the token and your Cloudflare account email

# Set credentials - NEVER COMMIT THESE!
export CLOUDFLARE_API_TOKEN="your-api-token-here"
export CLOUDFLARE_EMAIL="your-cloudflare-email"
export DOMAIN="yourdomain.com"
export TUNNEL_NAME="labber-k8s"  # Must match config.yaml
```

#### 2. Cloudflare Tunnel 🌐

```bash
# First-time setup only
# ---------------------
# Install cloudflared
# Linux:
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
# macOS:
brew install cloudflare/cloudflare/cloudflared

# Authenticate (opens browser)
cloudflared tunnel login

# Generate credentials (run from $HOME)
cloudflared tunnel create $TUNNEL_NAME
cloudflared tunnel token --cred-file tunnel-creds.json $TUNNEL_NAME

export DOMAIN="yourdomain.com"
export TUNNEL_NAME="labber-k8s"  # This should match the name in your config.yaml

# Create namespace for cloudflared
kubectl create namespace cloudflared

# Create Kubernetes secret
kubectl create secret generic tunnel-credentials \
  --namespace=cloudflared \
  --from-file=credentials.json=tunnel-credentials.json

# SECURITY: Destroy local credentials ( Optional )
rm -v tunnel-creds.json && echo "Credentials file removed"

# Configure DNS
TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')
cloudflared tunnel route dns $TUNNEL_ID "*.$DOMAIN"
```

## Boostrapping the cluster, after it has been built by Terraform

There are several core components to 'set up' before the rest of the cluster can be built and managed by ArgoCD. Here is a brief list, in order of importance

1. Networking - Cilium - Wave 0
2. External Secrets / 1Password Connect - Wave 0
3. Storage Provider - Proxmox CSI Plugin - Wave 1
4. most everything else - Wave 2 and beyond

### Networking

#### Cilium

A basic installation of Cilium is installed into the cluster using Talos' inline manifests feature. This allows the cluster to boot with basic support. However, there are still some extra steps required.

This is a prerequisite for Cilium's Gateway API integration.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/standard-install.yaml

# Apply experimental features with server-side apply to account for CRD annotation length
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.4.0/experimental-install.yaml
```

#### Certificate Management

```bash
# Create cert-manager secrets
kubectl create namespace cert-manager

kubectl create secret generic cloudflare-api-token -n cert-manager \
  --from-literal=api-token=$CLOUDFLARE_API_TOKEN \
  --from-literal=email=$CLOUDFLARE_EMAIL

# Verify secrets
kubectl get secret cloudflare-api-token -n cert-manager -o jsonpath='{.data.email}' | base64 -d

kubectl get secret cloudflare-api-token -n cert-manager -o jsonpath='{.data.api-token}' | base64 -d
```

### Secret Management

Pre-requisite in order to deploy further resources, like Storage Driver, etc.
This cluster uses [1Password Connect](https://developer.1password.com/docs/connect) and [External Secrets Operator](https://external-secrets.io/) to manage secrets.

1. **Generate 1Password Connect Credentials**: Follow the [1Password documentation](https://developer.1password.com/docs/connect/get-started#step-2-deploy-the-1password-connect-server) to generate your `1password-credentials.json` file and your access token.

2. **Create Namespaces**:

    ```bash
    kubectl create namespace 1passwordconnect
    kubectl create namespace external-secrets
    ```

3. **Create Kubernetes Secrets**:

    ```bash
    # Athenticate with 1Password
    eval $(op signin)

    export OP_CREDENTIALS=$(op read op://k8s-secrets/1passwordconnect/1password-credentials.json | base64 | tr -d '\n')
    export OP_CONNECT_TOKEN=$(op read 'op://k8s-secrets/1password-operator-token/password')

    kubectl create secret generic 1password-credentials \
      --namespace 1passwordconnect \
      --from-literal=1password-credentials.json="$OP_CREDENTIALS"

    kubectl create secret generic 1password-operator-token \
      --namespace 1passwordconnect \
      --from-literal=token="$OP_CONNECT_TOKEN"

    kubectl create secret generic 1passwordconnect \
      --namespace external-secrets \
      --from-literal=token="$OP_CONNECT_TOKEN"


### Storage

#### Proxmox CSI Plugin

for using the proxmox csi plugin, https://github.com/sergelogvinov/proxmox-csi-plugin/blob/main/docs/install.md

label all nodes with region (proxmox cluster name), and zone (node name)

```bash

kubectl label nodes --all topology.kubernetes.io/region=homebound
kubectl label nodes --all topology.kubernetes.io/zone=proxmox
```

### External DNS

The DNSEndpoint resource is used, which requires the DNSEndpoint CRD to be installed. This must be installed before Argo's HTTPRoute/DNS Endpoint is created so as not to block the ArgoCD bootstrap process.

1. Install CRD (tag branch should match semVer of helm chart version. eg. chart version v1.19.0 -> v0.19.0)
  `kubectl create -f https://raw.githubusercontent.com/kubernetes-sigs/external-dns/refs/tags/v0.19.0/config/crd/standard/dnsendpoints.externaldns.k8s.io.yaml`

### Final Bootstrapping

This final step uses our "App of Apps" pattern to bootstrap the entire cluster. This is a multi-step process to avoid race conditions with CRD installation.

```bash
./bootstrap-argocd.sh
```

### Cluster Maintenance

#### Upgrading Nodes

When a new version of Talos is released or system extensions in `iac/talos/talconfig.yaml` are changed, follow this process to upgrade your nodes. This method uses the direct `upgrade` command to ensure the new system image is correctly applied, which is more reliable than `apply-config` for image changes.

**Important:** Always upgrade control plane nodes **one at a time**, waiting for each node to successfully reboot and rejoin the cluster before proceeding to the next. This prevents losing etcd quorum. Worker nodes can be upgraded in parallel after the control plane is healthy.

1. **Update Configuration**:
    Modify `iac/talos/talconfig.yaml` with the new `talosVersion` or changes to `systemExtensions`.

2. **Ensure Environment is Set**:
    Make sure your `TALOSCONFIG` variable is pointing to your generated cluster configuration file as described in the Quick Start.

3. **Upgrade a Control Plane Node**:
    Run the following commands from the root of the repository. Replace `<node-name>` and `<node-ip>` with the target node's details. Run this for each control plane node sequentially.

    ```bash
    # Example for the first control plane node
    NODE_NAME="talos-cluster-control-00"
    NODE_IP="172.16.8.11" # Replace with your node's IP
    INSTALLER_URL=$(talhelper genurl installer -c iac/talos/talconfig.yaml -n "$NODE_NAME")
    talosctl upgrade --nodes "$NODE_IP" --image "$INSTALLER_URL"
    ```

    Wait for the command to complete and verify the node is healthy with `talosctl health --nodes <node-ip>` before moving to the next control plane node.

4. **Upgrade Worker Nodes**:
    Once the control plane is fully upgraded and healthy, you can upgrade the worker nodes. These can be run in parallel from separate terminals.

    ```bash
    # Example for the GPU worker node
    NODE_NAME="talos-cluster-gpu-worker-00"
    NODE_IP="192.168.10.200" # Replace with your node's IP
    INSTALLER_URL=$(talhelper genurl installer -c iac/talos/talconfig.yaml -n "$NODE_NAME")
    talosctl upgrade --nodes "$NODE_IP" --image "$INSTALLER_URL"

### Credits

Based on Mitch Ross' [🚀 Talos ArgoCD Proxmox Cluster](https://github.com/mitchross/talos-argocd-proxmox) homelab project. This project extends upon that with the inclusion of BGP networking for the Cilium CNI, Proxmox CSI Plugin and more.