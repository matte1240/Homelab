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
    default = "debian-server-trixie"
}

variable "version" {
    type    = string
    default = "13.0.0"
}

locals {
    disk_storage = "data"
}

source "proxmox-iso" "debian-server-trixie" {
    proxmox_url = "${var.proxmox_api_url}"
    username    = "${var.proxmox_username}"
    password    = "${var.proxmox_password}"
    insecure_skip_tls_verify = true
    task_timeout = "10m"

    node                 = "pve"
    vm_id                = "902"
    vm_name              = "debian-server-trixie-template"
    template_description = "Debian Server Trixie 13.0.0 Template"
    boot_iso {
        type             = "scsi"
        iso_url          = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso"
        iso_storage_pool = "local"
        iso_download_pve = true
        unmount          = true
        iso_checksum     = "sha256:e363cae0f1f22ed73363d0bde50b4ca582cb2816185cf6eac28e93d9bb9e1504"
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
      "<wait><esc><wait>auto preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg netcfg/get_hostname=debian-template<enter>"
    ]
    http_directory          = "http"
    http_port_min           = 8802
    http_port_max           = 8802
    http_bind_address       = "192.168.178.77"
    ssh_username            = "debian"
    ssh_password            = "debian"
    ssh_timeout             = "45m"
    ssh_pty                 = true
    ssh_handshake_attempts  = "100"
    ssh_keep_alive_interval = "5s"
    ssh_port                = 22
    ssh_wait_timeout        = "45m"
}

build {
    name    = "debian-server-trixie"
    sources = ["source.proxmox-iso.debian-server-trixie"]

    provisioner "shell" {
        inline = [
            "echo 'Connected via SSH successfully!'",
            "echo 'Waiting for system to be fully ready...'",
            "sleep 30",
            "echo 'Updating package cache...'",
            "sudo apt update",
            "echo 'Installing systemd-resolved for better DNS management...'",
            "sudo apt install -y systemd-resolved",
            "echo 'Configuring systemd-resolved...'",
            "sudo tee /etc/systemd/resolved.conf > /dev/null <<EOF",
            "[Resolve]",
            "DNS=192.168.178.2 192.168.178.3",
            "FallbackDNS=1.1.1.1 8.8.8.8",
            "Domains=~.",
            "Cache=yes",
            "DNSStubListener=yes",
            "EOF",
            "echo 'Enabling systemd-resolved...'",
            "sudo systemctl enable systemd-resolved",
            "echo 'Setting up resolv.conf symlink...'",
            "sudo rm -f /etc/resolv.conf",
            "sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf",
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
