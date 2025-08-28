#cloud-config

# Basic system configuration
hostname: ${hostname}
manage_etc_hosts: true

# User configuration
users:
  - name: ${username}
    groups: sudo
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
%{ for key in split("\n", ssh_keys) ~}
%{ if length(trimspace(key)) > 0 ~}
      - ${trimspace(key)}
%{ endif ~}
%{ endfor ~}

# Disable root login
disable_root: true
ssh_pwauth: false

# System settings
timezone: ${timezone}
locale: ${locale}

# Package management
package_update: true
package_upgrade: true
packages:
%{ for package in packages ~}
  - ${package}
%{ endfor ~}

# Commands to run
runcmd:
%{ for command in run_commands ~}
  - ${command}
%{ endfor ~}
  - systemctl enable ssh
  - systemctl start ssh

# Final message
final_message: "Cloud-init setup completed successfully!"