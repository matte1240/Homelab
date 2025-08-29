# Proxmox connection settings (adatta questi valori al tuo ambiente)
proxmox_api_url  = "https://192.168.178.70:8006/api2/json"
proxmox_token_id    = "root@pam!terraform"  # Token API Proxmox
proxmox_token_secret = "95b63b1e-a53a-4e20-a96f-5ef729cfcbcd"                 # Secret del token
proxmox_node     = "pve"

# VM configuration
vm_name       = "debian-vm-01"
vm_id         = 301
vm_cores      = 4         # Come nel tuo template Packer
vm_memory     = 4096      # Come nel tuo template Packer  
template_name = "debian-server-trixie-template"

# Storage and network (basato sul tuo setup esistente)
storage_pool   = "data"    # Dal tuo file Packer
disk_size      = "25G"     # Come nel tuo template Packer
network_bridge = "vmbr0"

# Cloud-init configuration
ci_user       = "debian"
ci_password   = "debian"   # Password temporanea, usa SSH keys
search_domain = "lan"


# SSH keys (la tua chiave pubblica esistente)
ssh_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCa7rARd0MiXcM+/FFMk3hpNlThZ/xvc8oYroWQdL49SwASpA8gKtZTjfZDE8tTb3zd34gdmA28Hc6SEe/k8kdbLEqCtQi5G5BgOFzNUFW/RuxzGhUG13i3aBUyCw9RL24ZvtSg/g5cJNu2JVjhOQfT3SLkU5SoIcnjZ0ZwZcqA9LiKzraSL3M49sbR00ETdVQ0ddvAUtpzxvSPiFDQ0tOvU8omBc+YfZhnDs1zU2l2uMms/nVzOhPxpAupWz2dkGhLNAEJyOpFm2bclP0FzUoQYbe6lsFpeR3Qg6G6RlJI1wEAcpPcORN8w/miGiMNZdTMkC7OZ6dPDVwr7gEx5Q2DjKOC8EphAGL0YPHhpfd+0Y/qc26vhD1GG6AtishxnMNfIJ4MbqEMFLwcCgjpRKr5lqNqOlygRZnugZ3gPQuPtLuQz+YWvZiys1AeKDmeToira8NluXLpGyaJEYVcAK9PSflpNfLL+/Nhuc+6WnZVKyQswVeI/qfWGL9II9ql9IjYnOJk2WLxFG3TYZTEIneLj1yT+fZjDwDWh3JrgJwvfkwAxOUEEK0bGZ/nWmKYkgUOoTAw4MZNJ26YjmNl7K1Hin8v7VzrMnZfysv/CmrcBXGe8FLHSJuwBPrn2uzRbA4nSnG7t9rTbwfEqz3LafDdCI4LC4vOnAvQSrBgiFoYfQ== ubuntu@packer-build"

# Pacchetti aggiuntivi da installare
packages = [
  "qemu-guest-agent",
  "sudo", 
  "curl",
  "wget",
  "vim",
  "htop",
  "git",
  "unzip"
]

# Configurazione IP statica per VM Debian
ip_config = {
  ip      = "192.168.178.21/24"
  gateway = "192.168.178.1"
}