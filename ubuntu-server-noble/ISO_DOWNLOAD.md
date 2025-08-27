# 📥 Automatic ISO Download Feature

## Overview

Starting from **Packer Plugin Proxmox v1.1.7**, you can now configure Packer to download ISO files directly on the Proxmox VE node instead of downloading them locally and then uploading to Proxmox.

## Benefits

### 🚀 **Performance**
- **No local download**: ISO files are downloaded directly to the Proxmox storage
- **No upload overhead**: Eliminates the need to transfer large ISO files from Packer to Proxmox
- **Faster builds**: Especially beneficial when Packer runs on a different machine than Proxmox

### 🌐 **Network Efficiency** 
- **Reduced bandwidth**: ISO download happens directly on the Proxmox node
- **Better for remote setups**: Perfect when Packer runs from a different location than Proxmox

### 💾 **Storage Optimization**
- **No local storage needed**: ISOs are stored directly in Proxmox storage pools
- **Automatic cleanup**: ISOs can be automatically removed after template creation

## Configuration

### Boot ISO with Auto-Download

```hcl
boot_iso {
    type             = "scsi"
    iso_url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
    iso_storage_pool = "local"
    iso_download_pve = true        # 🔑 Key feature!
    unmount          = true
    iso_checksum     = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}
```

### Additional ISO Files with Auto-Download

```hcl
additional_iso_files {
    type             = "ide"
    iso_url          = "https://example.com/drivers.iso"
    iso_storage_pool = "local"
    iso_download_pve = true        # 🔑 Downloads directly to Proxmox
    unmount          = true
    iso_checksum     = "sha256:your_checksum_here"
}
```

## Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `iso_url` | string | Direct URL to download the ISO file | Required |
| `iso_storage_pool` | string | Proxmox storage pool where ISO will be downloaded | Required |
| `iso_download_pve` | bool | Enable direct download to Proxmox node | `false` |
| `iso_checksum` | string | SHA256 checksum for verification | Required |
| `unmount` | bool | Remove ISO after template creation | `false` |

## Migration from Local ISO

### Before (Manual Upload Required)
```hcl
boot_iso {
    type         = "scsi"
    iso_file     = "local:iso/ubuntu-24.04.3-live-server-amd64.iso"  # Must exist!
    unmount      = true
    iso_checksum = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}
```

### After (Automatic Download)
```hcl
boot_iso {
    type             = "scsi"
    iso_url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
    iso_storage_pool = "local"
    iso_download_pve = true        # ✨ Magic happens here!
    unmount          = true
    iso_checksum     = "sha256:c3514bf0056180d09376462a7a1b4f213c1d6e8ea67fae5c25099c6fd3d8274b"
}
```

## Use Cases

### 🏠 **Home Lab Setup**
- Packer running on laptop/desktop
- Proxmox running on separate server
- ISOs downloaded directly to server storage

### ☁️ **Remote CI/CD**
- GitHub Actions or similar CI system
- Proxmox in datacenter or cloud
- No need to manage ISO artifacts

### 🔄 **Template Automation**
- Automatic builds with latest ISOs
- Dynamic template creation
- No manual ISO management

## Storage Pools

Common Proxmox storage pools for ISO download:

| Pool | Description | Recommended Use |
|------|-------------|-----------------|
| `local` | Default local storage | ✅ Most common choice |
| `local-lvm` | LVM storage | ❌ Not for ISOs |
| `data` | Additional storage | ✅ If configured for ISOs |

## Error Handling

The plugin will:
1. **Verify checksum** before starting the build
2. **Retry download** if network issues occur  
3. **Clean up** failed downloads automatically
4. **Provide detailed logs** for troubleshooting

## Version Requirements

- **Minimum Plugin Version**: `v1.1.7+`
- **Current Implementation**: Using `v1.2.3` ✅
- **Proxmox VE**: Any version with API support

## Troubleshooting

### Common Issues

1. **Storage pool not found**
   ```
   Error: storage pool 'xyz' not found
   ```
   **Solution**: Verify storage pool name in Proxmox web interface

2. **Permission denied**
   ```
   Error: insufficient privileges
   ```
   **Solution**: Ensure Proxmox user has storage management permissions

3. **Network timeout**
   ```
   Error: download timeout
   ```
   **Solution**: Check firewall and internet connectivity on Proxmox node

### Debug Commands

```bash
# Check available storage pools
pvesm status

# Test download manually
wget -O /tmp/test.iso "https://example.com/file.iso"

# Verify checksum
sha256sum /tmp/test.iso
```

---

**💡 Tip**: This feature is perfect for automated environments where manual ISO management is not practical!
