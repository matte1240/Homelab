# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Packer template repository for creating VM templates on Proxmox VE. It contains templates for Ubuntu Server Noble (24.04) and Debian Server Trixie with Cloud-Init integration.

## Common Commands

All builds are managed through the Makefile:

```bash
# Check prerequisites and configuration
make check

# Build all templates
make build-all

# Build specific templates
make build-ubuntu
make build-debian-trixie

# Validate all templates without building
make validate-all

# Debug SSH configuration
make debug-ssh

# Show IP configuration
make show-ips

# Clean temporary files
make clean
```

### Manual Packer Commands

When working directly with Packer:

```bash
# Validate a template
cd ubuntu-server-noble && packer validate -var-file="../credentials.pkr.hcl" ubuntu-server-noble.pkr.hcl

# Build a template with logging
cd ubuntu-server-noble && PACKER_LOG=1 packer build -var-file="../credentials.pkr.hcl" ubuntu-server-noble.pkr.hcl
```

## Architecture

### Directory Structure

- **credentials.pkr.hcl**: Proxmox API credentials (copy from .example file)
- **ubuntu-server-noble/**: Ubuntu 24.04 LTS template
- **debian-server-trixie/**: Debian 13 Trixie template

Each template directory contains:
- `*.pkr.hcl`: Main Packer configuration
- `plugins.pkr.hcl`: Packer plugin definitions
- `http/`: Autoinstall/preseed configuration files
- `files/`: Cloud-Init configuration files (99-pve.cfg)

### Template Configuration

Templates are configured with:
- **VM IDs**: Ubuntu (900), Debian Trixie (902)
- **Storage**: Uses "data" pool for disks, "local" for ISOs
- **Networking**: virtio on vmbr0 bridge
- **Cloud-Init**: Integrated with Proxmox datasource configuration

### ISO Download Feature

Templates support automatic ISO download to Proxmox using `iso_download_pve = true`. This eliminates manual ISO uploads and improves build performance. See ubuntu-server-noble/ISO_DOWNLOAD.md for detailed configuration.

### Provisioning Process

1. **Boot**: Uses autoinstall (Ubuntu) or preseed (Debian) for unattended installation
2. **SSH Setup**: Configures SSH keys from http server during build
3. **Cleanup**: Removes SSH host keys, machine-id, and cleans package cache
4. **Cloud-Init**: Installs 99-pve.cfg for Proxmox datasource integration

## Development Notes

- Templates require SSH key at `~/.ssh/id_rsa` for authentication
- HTTP server binds to specific IP (192.168.178.77:8802) - update in templates as needed
- All templates use Cloud-Init for final VM provisioning in Proxmox
- Credentials file must be created from the .example template before building
- Makefile includes comprehensive validation and debugging targets