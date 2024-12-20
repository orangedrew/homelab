module "talos" {
  source = "./talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.8.0-alpha.1"
    update_version = "v1.8.0-alpha.1" # renovate: github-releases=siderolabs/talos
    schematic = file("${path.module}/talos/image/schematic.yaml")
  }

  cilium = {
    values = file("${path.module}/../../k8s/infra/network/cilium/values.yaml")
    install = file("${path.module}/talos/inline-manifests/cilium-install.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "192.168.1.102"
    gateway         = "192.168.1.1"
    talos_version   = "v1.8"
    proxmox_cluster = "homelab"
  }

  nodes = {
    "ctrl-00" = {
      host_node     = "red"
      machine_type  = "controlplane"
      ip            = "192.168.1.100"
      mac_address   = ""
      vm_id         = 800
      cpu           = 8
      ram_dedicated = 20480
      igpu          = true
    }
    "ctrl-01" = {
      host_node     = "green"
      machine_type  = "controlplane"
      ip            = "192.168.1.101"
      mac_address   = ""
      vm_id         = 801
      cpu           = 4
      ram_dedicated = 20480
      igpu          = true
    }
    "ctrl-02" = {
      host_node     = "blue"
      machine_type  = "controlplane"
      ip            = "192.168.1.102"
      mac_address   = ""
      vm_id         = 802
      cpu           = 4
      ram_dedicated = 4096
    }
    #    "work-00" = {
    #      host_node     = "abel"
    #      machine_type  = "worker"
    #      ip            = "192.168.1.110"
    #      mac_address   = "BC:24:11:2E:A8:00"
    #      vm_id         = 810
    #      cpu           = 8
    #      ram_dedicated = 4096
    #    }
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

module "volumes" {
  depends_on = [module.proxmox_csi_plugin]
  source = "./bootstrap/volumes"

  providers = {
#    restapi    = restapi
    kubernetes = kubernetes
  }
  proxmox_api = var.proxmox
  volumes = {
  }
}
