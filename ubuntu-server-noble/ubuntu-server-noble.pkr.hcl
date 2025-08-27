variable "proxmox_api_url" {
    type = string
}

variable "proxmox_username" {
    type = string
}

variable "proxmox_password" {
    type      = string
    sensitive = true
}

variable "name" {
    type    = string
    default = "ubuntu-server-noble"
}

variable "version" {
    type    = string
    default = "24.04"
}

locals {
    disk_storage = "data"
}

source "proxmox-iso" "ubuntu-server-noble" {
    proxmox_url = "${var.proxmox_api_url}"
    username    = "${var.proxmox_username}"
    password    = "${var.proxmox_password}"
    insecure_skip_tls_verify = true
    task_timeout = "10m"

    node                 = "pve"
    vm_id                = "901"
    vm_name              = "ubuntu-server-noble-template"
    template_description = "Ubuntu Server Noble 24.04 Template"
    boot_iso {
        type             = "scsi"
        iso_url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
        iso_storage_pool = "local"
        iso_download_pve = true
        unmount          = true
        iso_checksum     = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
    }

    qemu_agent = true
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size         = "25G"
        format            = "raw"
        storage_pool      = "${local.disk_storage}"
        type              = "virtio"
    }

    cores = "4"
    memory = "4096"

    network_adapters {
        model    = "virtio"
        bridge   = "vmbr0"
        firewall = "false"
    }

    cloud_init              = true
    cloud_init_storage_pool = "${local.disk_storage}"

    // Example of additional ISO files that can be downloaded directly to Proxmox
    // Uncomment to add tools or drivers during installation
    /*
    additional_iso_files {
        type             = "ide"
        iso_url          = "https://example.com/tools.iso"
        iso_storage_pool = "local"
        iso_download_pve = true
        unmount          = true
        iso_checksum     = "sha256:your_checksum_here"
    }
    */

    boot         = "c"
    boot_wait    = "10s"
    communicator = "ssh"
    boot_command = [
      "c<wait>linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<enter><wait>",
      "initrd /casper/initrd<enter><wait>",
      "boot<enter><wait>"
    ]
    http_directory          = "http"
    http_port_min           = 8802
    http_port_max           = 8802

    ssh_username            = "ubuntu"
    ssh_private_key_file    = "~/.ssh/id_rsa"
    ssh_timeout             = "45m"
    ssh_pty                 = true
    ssh_handshake_attempts  = "100"
    ssh_keep_alive_interval = "5s"
    ssh_port                = 22
    ssh_wait_timeout        = "45m"
    ssh_clear_authorized_keys = false
}

build {
    name    = "ubuntu-server-noble"
    sources = ["source.proxmox-iso.ubuntu-server-noble"]

    provisioner "shell" {
        inline = [
            "echo 'Connected via SSH successfully!'",
            "echo 'Waiting for system to be fully ready...'",
            "sleep 30",
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done",
            "echo 'Ensuring SSH service is running...'",
            "sudo systemctl is-active --quiet ssh || sudo systemctl restart ssh",
            "sudo systemctl enable ssh",
            "echo 'Ensuring qemu-guest-agent is running...'", 
            "sudo systemctl is-active --quiet qemu-guest-agent || sudo systemctl restart qemu-guest-agent",
            "sudo systemctl enable qemu-guest-agent",
            "echo 'System is ready, proceeding with cleanup...'",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    provisioner "file" {
        source      = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    provisioner "shell" {
        inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
    }
}
