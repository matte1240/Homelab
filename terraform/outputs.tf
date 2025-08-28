# Output values
output "vm_id" {
  description = "ID of the created VM"
  value       = proxmox_virtual_environment_vm.debian_vm.vm_id
}

output "vm_name" {
  description = "Name of the created VM"
  value       = proxmox_virtual_environment_vm.debian_vm.name
}

output "vm_ipv4_address" {
  description = "IPv4 address of the VM"
  value       = try(proxmox_virtual_environment_vm.debian_vm.ipv4_addresses[1][0], "")
}

output "vm_ssh_host" {
  description = "SSH connection string"  
  value       = try("${var.ci_user}@${proxmox_virtual_environment_vm.debian_vm.ipv4_addresses[1][0]}", "")
}