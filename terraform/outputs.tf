# Ubuntu VM outputs
output "ubuntu_vm_ids" {
  description = "IDs of the created Ubuntu VMs"
  value       = proxmox_virtual_environment_vm.ubuntu_vm[*].vm_id
}

output "ubuntu_vm_names" {
  description = "Names of the created Ubuntu VMs"
  value       = proxmox_virtual_environment_vm.ubuntu_vm[*].name
}

output "ubuntu_vm_ip_addresses" {
  description = "IPv4 addresses of the created Ubuntu VMs"
  value       = [for vm in proxmox_virtual_environment_vm.ubuntu_vm : try(vm.ipv4_addresses[1][0], "")]
}

output "ubuntu_vm_ssh_hosts" {
  description = "SSH connection strings for the created Ubuntu VMs"
  value       = [for vm in proxmox_virtual_environment_vm.ubuntu_vm : try("${var.ci_user}@${vm.ipv4_addresses[1][0]}", "")]
}

# Summary output
output "deployment_summary" {
  description = "Summary of deployed Ubuntu VMs"
  value = {
    vm_count    = var.vm_count
    vm_prefix   = var.vm_name_prefix
    id_range    = "${var.vm_id_start} - ${var.vm_id_start + var.vm_count - 1}"
    ip_range    = var.use_dhcp ? "DHCP assigned" : "${var.ip_base_address}${var.ip_start} - ${var.ip_base_address}${var.ip_start + var.vm_count - 1}"
    template_id = var.ubuntu_template_id
  }
}