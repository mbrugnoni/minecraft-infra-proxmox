output "ip_address" {
  value = proxmox_vm_qemu.minecraft1[*].default_ipv4_address
}
