# Terraform configuration for Proxmox VE
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

# Configure the Proxmox Provider
provider "proxmox" {
  endpoint = var.proxmox_api_url
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure = true
}

# Create Ubuntu VMs with incremental IDs and IPs
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  count     = var.vm_count
  name      = "${var.vm_name_prefix}-${format("%02d", count.index + 1)}"
  node_name = var.proxmox_node
  vm_id     = var.vm_id_start + count.index
  
  # Clone from Ubuntu template
  clone {
    vm_id = var.ubuntu_template_id
  }
  
  # Agent
  agent {
    enabled = true
  }
  
  # CPU and Memory
  cpu {
    cores = var.vm_cores
  }
  
  memory {
    dedicated = var.vm_memory
  }
  
  # Network configuration
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  # Cloud-init configuration
  initialization {
    datastore_id = var.storage_pool
    
    user_account {
      username = var.ci_user
      password = var.ci_password
      keys     = [var.ssh_keys]
    }
    
    dns {
      servers = var.dns_servers
      domain  = var.search_domain
    }
    
    ip_config {
      ipv4 {
        address = var.use_dhcp ? "dhcp" : "${var.ip_base_address}${var.ip_start + count.index}/${var.ip_subnet_mask}"
        gateway = var.use_dhcp ? null : var.ip_gateway
      }
    }
  }
}