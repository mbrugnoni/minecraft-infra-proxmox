terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://192.168.50.72:8006/api2/json"
  # api token id is in the form of: <username>@pam!<tokenId>
  pm_api_token_id     = "api_user@pam!api-token-1"
  pm_api_token_secret = "6bdd0a35-bc4a-4b81-aef2-3388ec026fc0"
  pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "minecraft1" {
  count       = 1
  name        = "minecraft${count.index + 1}"
  target_node = var.proxmox_host
  clone       = var.template_name
  agent       = 1
  os_type     = "cloud-init"
  cores       = 2
  sockets     = 1
  cpu         = "host"
  memory      = 4096
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"
  disk {
    slot     = 0
    size     = "10G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp"

  sshkeys = <<EOF
  ${var.ssh_key}
  EOF
}

resource "local_file" "tf_ansible_hosts" {
  content  = proxmox_vm_qemu.minecraft1[0].default_ipv4_address
  filename = "./tf_ansible_hosts"
  provisioner "local-exec" {
    command = "sleep 90;export ANSIBLE_HOST_KEY_CHECKING=False; ansible-playbook -i ${self.filename} minecraft_server_config.yml"
  }
}

