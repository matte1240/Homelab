# Copilot Instructions for Homelab Project

## Project Overview
This is a Packer-based infrastructure project for creating optimized VM templates for Proxmox VE. The project builds Ubuntu and Debian server templates with Cloud-Init integration for automated deployment.

## Architecture & Components

### Template Structure
- **Multi-OS support**: Each OS has its own directory (`ubuntu-server-noble/`, `debian-server-trixie/`)
- **Shared credentials**: `credentials.pkr.hcl` contains Proxmox API credentials (never commit this file)
- **Consistent patterns**: Each template follows the same structure with `.pkr.hcl`, `http/`, and `files/` directories

### Key Files per Template
- `{os}-{version}.pkr.hcl` - Main Packer configuration with VM specs, provisioning steps
- `http/user-data` - Cloud-Init autoinstall configuration (Ubuntu) or preseed (Debian)
- `http/meta-data` - Cloud-Init metadata (usually minimal)
- `files/99-pve.cfg` - Proxmox-specific Cloud-Init datasource configuration

## Critical Workflows

### Build Process
```bash
# Workflow automatico con Makefile (raccomandato)
make check                    # Verifica prerequisiti
make validate-all             # Valida tutti i template
make build-ubuntu             # Costruisce solo Ubuntu
make build-all                # Costruisce tutti i template

# Workflow manuale
packer validate -var-file="../credentials.pkr.hcl" {template}.pkr.hcl
packer build -var-file="../credentials.pkr.hcl" {template}.pkr.hcl
```

### Development Workflow
```bash
make help                     # Mostra tutti i target disponibili
make show-ips                 # Verifica configurazione IP
make debug-ssh                # Debug problemi SSH
make dev-check                # Controlli struttura progetto
```

### Credential Setup
1. Copy `credentials.pkr.hcl.example` to `credentials.pkr.hcl`
2. Use Proxmox API tokens, not passwords: `username@pam!token_id`
3. Format: `https://PROXMOX_IP:8006/api2/json`

### SSH Key Management
- SSH keys must be embedded in `http/user-data` for Ubuntu templates
- Use `ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "ubuntu@packer-build"`
- Update `ssh_authorized_keys` section in user-data with public key

## Project-Specific Conventions

### VM ID Assignment
- Ubuntu Noble: VM ID 900
- Debian Trixie: VM ID 903
- Follow sequential numbering for new templates

### Storage Configuration
- Use `local.disk_storage = "data"` for consistency
- ISO storage pool: `"local"` 
- Template storage: `"data"` pool
- Disk format: `"raw"` for better performance

### ISO Download Strategy
**Modern approach (v1.1.7+)**: Use `iso_download_pve = true` for automatic download to Proxmox:
```hcl
boot_iso {
    iso_url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
    iso_storage_pool = "local"
    iso_download_pve = true  # Downloads directly to Proxmox
    iso_checksum     = "sha256:..."
}
```

**Legacy approach**: Comment out auto-download, use pre-uploaded ISOs with `iso_file`

### Cloud-Init Integration
- Always include `files/99-pve.cfg` provisioning step for Proxmox compatibility
- Use `qemu_agent = true` for proper VM management
- Disable swap in storage layout: `swap: { size: 0 }`
- Set `cloud_init_storage_pool = "${local.disk_storage}"`

### Network Configuration
- HTTP bind address: Update with your actual IP (check with `ip route get 1.1.1.1 | grep -oP 'src \K\S+'`)
- Fixed ports: `8802` for HTTP server consistency
- Bridge: `vmbr0` (Proxmox default)
- Network model: `virtio` for performance

## Troubleshooting Patterns

### Common VM ID conflicts
Templates use fixed VM IDs - check Proxmox for existing VMs before building

### SSH timeout issues  
- **IP mismatch**: Most common cause - verify `http_bind_address` matches your actual IP
- Verify SSH key in `user-data` matches your private key
- Check `ssh_timeout = "30m"` for slow builds
- Ensure `ssh_pty = true` for compatibility
- Use debug script: `./debug-ssh.sh` to identify network issues

### Boot command timing
- Ubuntu uses GRUB editing: `<esc>e<down><down><down><end>`
- Debian uses different boot sequence - check template-specific commands
- Adjust `boot_wait` if timing issues occur

## Security Considerations
- Never commit `credentials.pkr.hcl` - it's in `.gitignore`
- SSH password auth disabled for root in templates
- Use `sudo: ALL=(ALL) NOPASSWD:ALL` for automation but secure with SSH keys
- Templates create `ubuntu` user with sudo access

## Template Customization
- Resource allocation: Modify `cores`, `memory`, `disk_size` in `.pkr.hcl`
- Package installation: Add to `packages:` array in `user-data`
- Network config: Modify `network:` section for static IPs
- Timezone: Set in `user-data` under `timezone:`
