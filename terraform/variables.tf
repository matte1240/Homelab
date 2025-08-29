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

# VM configuration variables
variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "debian-vm"
}

variable "vm_id" {
  description = "VM ID"
  type        = number
  default     = 301
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Amount of memory in MB"
  type        = number
  default     = 2048
}

variable "template_name" {
  description = "Template to clone from"
  type        = string
  default     = "debian-server-trixie-template"
}

variable "storage_pool" {
  description = "Storage pool name"
  type        = string
  default     = "data"
}

variable "disk_size" {
  description = "Disk size (if different from template's 25G, will resize the disk)"
  type        = string
  default     = "25G"
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
  default     = "debian"
}

variable "ci_password" {
  description = "Cloud-init password"
  type        = string
  sensitive   = true
  default     = null
}

variable "ssh_keys" {
  description = "SSH public keys"
  type        = string
  default     = ""
}

variable "search_domain" {
  description = "Search domain"
  type        = string
  default     = "local"
}

variable "dns_servers" {
  description = "List of DNS servers"
  type        = list(string)
  default     = ["192.168.178.2", "192.168.178.3", "1.1.1.1"]
}

variable "ip_config" {
  description = "IP configuration (optional - use DHCP if null)"
  type = object({
    ip      = string
    gateway = string
  })
  default = null
}

# Additional cloud-init variables
variable "packages" {
  description = "List of packages to install (informational only - handled by template)"
  type        = list(string)
  default = [
    "qemu-guest-agent",
    "sudo",
    "curl",
    "wget",
    "vim",
    "htop",
    "git",
    "unzip"
  ]
}

variable "timezone" {
  description = "System timezone (informational only - handled by template)"
  type        = string
  default     = "Europe/Rome"
}

variable "locale" {
  description = "System locale (informational only - handled by template)"
  type        = string
  default     = "en_US.UTF-8"
}

variable "run_commands" {
  description = "Commands to run during cloud-init (informational only - handled by template)"
  type        = list(string)
  default = [
    "systemctl enable qemu-guest-agent",
    "systemctl start qemu-guest-agent"
  ]
}