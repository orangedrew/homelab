module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.8.0"
    update_version = "v1.8.2" # renovate: github-releases=siderolabs/talos
    schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "10.0.0.15"
    gateway         = "10.0.0.1"
    talos_version   = "v1.8"
    proxmox_cluster = "homelab"
  }

  nodes = {
    "ctrl-00" = {
      host_node     = "red"
      machine_type  = "controlplane"
      ip            = "10.0.0.10"
      mac_address   = "BC:24:11:2E:C8:00"
      vm_id         = 800
      cpu           = 8
      ram_dedicated = 20480
      igpu          = true
    }
    "ctrl-01" = {
      host_node     = "green"
      machine_type  = "controlplane"
      ip            = "10.0.0.11"
      mac_address   = "BC:24:11:2E:C8:01"
      vm_id         = 801
      cpu           = 4
      ram_dedicated = 20480
      igpu          = true
    }
    "ctrl-02" = {
      host_node     = "blue"
      machine_type  = "controlplane"
      ip            = "10.0.0.12"
      mac_address   = "BC:24:11:2E:C8:02"
      vm_id         = 802
      cpu           = 4
      ram_dedicated = 4096
    }
    "work-00" = {
      host_node     = "red"
      machine_type  = "worker"
      ip            = "10.0.0.20"
      mac_address   = "BC:24:11:2E:A8:00"
      vm_id         = 810
      cpu           = 8
      ram_dedicated = 4096
    }
  }

}

module "sealed_secrets" {
  depends_on = [module.talos]
  source = "./bootstrap/sealed-secrets"

  providers = {
    kubernetes = kubernetes
  }

  // openssl req -x509 -days 365 -nodes -newkey rsa:4096 -keyout sealed-secrets.key -out sealed-secrets.cert -subj "/CN=sealed-secret/O=sealed-secret"
  cert = {
    cert = file("${path.module}/bootstrap/sealed-secrets/certificate/sealed-secrets.cert")
    key = file("${path.module}/bootstrap/sealed-secrets/certificate/sealed-secrets.key")
  }
}

module "proxmox_csi_plugin" {
  depends_on = [module.talos]
  source = "./bootstrap/proxmox-csi-plugin"

  providers = {
    proxmox    = proxmox
    kubernetes = kubernetes
  }

  proxmox = var.proxmox
}

#module "volumes" {
#  depends_on = [module.proxmox_csi_plugin]
#  source = "./bootstrap/volumes"
#
#  providers = {
#    restapi    = restapi
#    kubernetes = kubernetes
#  }
#  proxmox_api = var.proxmox
#  volumes = {
#  }
#}
