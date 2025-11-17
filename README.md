configured cloud gateway fiber for BGP to use Cillium as my LB
router BGP ASN 65510
router id 172.16.72.10

peer remote-as 65512

all services will be advertised via BGP unless explicitly labeled with: cilium-lb-no-advertise=true

required credentials needed to apply for terraform

Backblaze key for S2 backend
Promox API key for API functions
Proxmox SSH user / private key for SSH operations

for using the proxmox csi plugin, https://github.com/sergelogvinov/proxmox-csi-plugin/blob/main/docs/install.md
label all nodes with region (proxmox cluster name), and zone (node name)
kubectl label nodes region1-node-1 topology.kubernetes.io/region=homebound
kubectl label nodes region1-node-1 topology.kubernetes.io/zone=proxmox