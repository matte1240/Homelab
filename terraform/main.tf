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

# Create Debian VM with cloud-init
resource "proxmox_virtual_environment_vm" "debian_vm" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  
  # Clone from template
  clone {
    vm_id = var.debian_template_id
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
        address = var.ip_config != null ? var.ip_config.ip : "dhcp"
        gateway = var.ip_config != null ? var.ip_config.gateway : null
      }
    }
  }
}

# Create Ubuntu VM with cloud-init
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = var.ubuntu_vm_name
  node_name = var.proxmox_node
  vm_id     = var.ubuntu_vm_id
  
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
    cores = 2
  }
  
  memory {
    dedicated = 2048
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
      username = "ubuntu"
      password = "ubuntu"
      keys     = [var.ssh_keys]
    }
    
    dns {
      servers = var.dns_servers
      domain  = var.search_domain
    }
    
    ip_config {
      ipv4 {
        address = var.ubuntu_ip_config != null ? var.ubuntu_ip_config.ip : "dhcp"
        gateway = var.ubuntu_ip_config != null ? var.ubuntu_ip_config.gateway : null
      }
    }
  }
}