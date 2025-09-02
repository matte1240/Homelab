# Proxmox connection variables
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID (format: username@pam!token_id)"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

# VM scaling variables
variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "vm_name_prefix" {
  description = "VM name prefix (will be followed by -01, -02, etc.)"
  type        = string
  default     = "ubuntu-vm"
}

variable "vm_id_start" {
  description = "Starting VM ID (subsequent VMs will increment from this)"
  type        = number
  default     = 300
}

# VM configuration variables
variable "vm_cores" {
  description = "Number of CPU cores per VM"
  type        = number
  default     = 4
}

variable "vm_memory" {
  description = "Amount of memory in MB per VM"
  type        = number
  default     = 4096
}

variable "ubuntu_template_id" {
  description = "VM ID of the Ubuntu template"
  type        = number
  default     = 900
}

variable "storage_pool" {
  description = "Storage pool name"
  type        = string
  default     = "data"
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

# Cloud-init variables
variable "ci_user" {
  description = "Cloud-init user"
  type        = string
  default     = "ubuntu"
}

variable "ci_password" {
  description = "Cloud-init password"
  type        = string
  sensitive   = true
  default     = "ubuntu"
}

variable "ssh_keys" {
  description = "SSH public keys"
  type        = string
  default     = ""
}

variable "search_domain" {
  description = "Search domain"
  type        = string
  default     = "lan"
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = ["192.168.178.2", "192.168.178.3", "1.1.1.1"]
}

# IP configuration variables
variable "use_dhcp" {
  description = "Use DHCP for IP assignment (if false, uses static IPs)"
  type        = bool
  default     = false
}

variable "ip_base_address" {
  description = "Base IP address (e.g., '192.168.178.' - note the trailing dot)"
  type        = string
  default     = "192.168.178."
}

variable "ip_start" {
  description = "Starting IP address number (will increment for each VM)"
  type        = number
  default     = 20
}

variable "ip_subnet_mask" {
  description = "Subnet mask (CIDR notation number)"
  type        = number
  default     = 24
}

variable "ip_gateway" {
  description = "Gateway IP address"
  type        = string
  default     = "192.168.178.1"
}