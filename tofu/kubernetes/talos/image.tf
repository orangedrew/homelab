locals {
  version = var.image.version
  schematic = var.image.schematic
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]
  #schematic_id = talos_image_factory_schematic.this.id
  image_id = "${local.schematic_id}_${local.version}"

  update_version = coalesce(var.image.update_version, var.image.version)
  update_schematic = coalesce(var.image.update_schematic, var.image.schematic)
  update_schematic_id = jsondecode(data.http.updated_schematic_id.response_body)["id"]
  #update_schematic_id = talos_image_factory_schematic.this.id
  update_image_id = "${local.update_schematic_id}_${local.update_version}"
}

data "http" "schematic_id" {
  url          = "${var.image.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic
}

data "http" "updated_schematic_id" {
  url          = "${var.image.factory_url}/schematics"
  method       = "POST"
  request_body = local.update_schematic
}

/* Testing out new provider schematic feature */

data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.image.version
  filters = {
    names = [
      "i915-ucode",
      "intel-ucode",
      "qemu-guest-agent"
    ]
  }
}

resource "talos_image_factory_schematic" "generated" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

output "schematic_id" {
  value = talos_image_factory_schematic.generated.id
}

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

resource "talos_image_factory_schematic" "updated" {
  schematic = local.update_schematic
}

/* Testing out new provider schematic feature */

resource "proxmox_virtual_environment_download_file" "this" {
  for_each = toset(distinct([for k, v in var.nodes : "${v.host_node}_${v.update == true ? local.update_image_id : local.image_id}"]))
  node_name    = split("_", each.key)[0]
  content_type = "iso"  # We might need to change this depending on what Proxmox expects
  datastore_id = var.image.proxmox_datastore
  file_name    = "talos-${split("_",each.key)[1]}-${split("_", each.key)[2]}-${var.image.platform}-${var.image.arch}.iso"  # Changed to .iso
  url          = "${var.image.factory_url}/image/${split("_", each.key)[1]}/${split("_", each.key)[2]}/${var.image.platform}-${var.image.arch}.iso"
  overwrite    = false
}
