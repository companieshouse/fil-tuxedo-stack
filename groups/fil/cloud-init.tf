data "cloudinit_config" "config" {
  count = var.instance_count

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/system-config.yml.tpl", {})
  }

  part {
      content_type = "text/cloud-config"
      content = templatefile("${path.module}/cloud-init/templates/tnsnames.ora.tpl", {
        tnsnames = jsondecode(data.vault_generic_secret.tns_names.data.tnsnames)
      })
      merge_type = var.user_data_merge_strategy
    }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/bootstrap-commands.yml.tpl", {
      instance_hostname = "${var.service_subtype}-${var.service}-${var.environment}-${count.index + 1}"
      lvm_block_devices = var.lvm_block_devices
    })
  }
}
