data "helm_template" "cilium_template" {
  name         = "cilium"
  repository   = "https://helm.cilium.io/"
  chart        = "cilium"
  namespace    = "kube-system"
  version      = "1.18.5"
  kube_version = local.kubeVersion

  set = [
    {
      name  = "ipam.mode"
      value = "kubernetes"
    },
    {
      name  = "kubeProxyReplacement"
      value = "true"
    },
    {
      name  = "bgpControlPlane.enabled"
      value = "true"
    },
    {
      name  = "cgroup.autoMount.enabled"
      value = "false"
    },
    {
      name  = "cgroup.hostRoot"
      value = "/sys/fs/cgroup"
    },
    {
      name  = "k8sServiceHost"
      value = "localhost"
    },
    {
      name  = "gatewayAPI.enabled"
      value = "false"
    },
    {
      name  = "gatewayAPI.enableAlpn"
      value = "true"
    },
    {
      name  = "gatewayAPI.enableAppProtocol"
      value = "true"
    },
    {
      name  = "k8sServicePort"
      value = "7445"
    }
  ]

  set_list = [
    {
      name  = "securityContext.capabilities.ciliumAgent"
      value = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
    },
    {
      name  = "securityContext.capabilities.cleanCiliumState"
      value = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
    }
  ]
}