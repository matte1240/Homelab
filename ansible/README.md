# Ansible Docker Compose Deployment

Simple Ansible structure for deploying Docker Compose v2 on Ubuntu servers.

## Quick Start

1. **Install requirements:**
```bash
cd ansible
ansible-galaxy collection install -r collections/requirements.yml
```

2. **Update inventory:**
Edit `inventories/dev/hosts` with your server details.

3. **Deploy everything:**
```bash
# Development environment
ansible-playbook site.yml

# Production environment  
ansible-playbook -i inventories/production/hosts site.yml
```

## Project Structure

```
ansible/
├── ansible.cfg                    # Ansible configuration
├── site.yml                      # Main deployment playbook
├── inventories/
│   ├── dev/                      # Development environment
│   │   ├── hosts                 # Inventory file
│   │   └── group_vars/all.yml    # Environment variables
│   └── production/               # Production environment
├── roles/
│   ├── common/                   # Basic system setup
│   ├── docker_install/           # Docker & Compose installation
│   └── docker_compose/           # Application deployment
├── playbooks/                    # Individual playbooks
└── collections/requirements.yml  # Required Ansible collections
```

## Available Playbooks

- `site.yml` - Complete deployment (system + docker + app)
- `playbooks/docker-only.yml` - Install Docker only
- `playbooks/deploy-app.yml` - Deploy application only

## Usage Examples

```bash
# Install Docker only
ansible-playbook playbooks/docker-only.yml

# Deploy application only
ansible-playbook playbooks/deploy-app.yml

# Deploy to specific host
ansible-playbook site.yml -l prod-server-01

# Use different environment
ansible-playbook -i inventories/production/hosts site.yml

# Run specific tags
ansible-playbook site.yml --tags docker,compose
```

## Configuration

### Application Setup

Edit `group_vars/all.yml` to configure your application:

```yaml
compose_services:
  - name: web
    image: "nginx:alpine"
    ports:
      - "80:8080"
    volumes:
      - "/opt/app/html:/usr/share/nginx/html:ro"
```

### Security Features

- Non-root containers
- Read-only filesystems
- Capability dropping
- Security options
- Secrets management

## Requirements

- Ubuntu 20.04+ target servers
- Ansible 2.9+
- community.docker collection 3.6+