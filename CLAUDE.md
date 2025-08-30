# Claude Instructions

## Project Overview
This is a **Homelab Infrastructure as Code** repository for managing Proxmox VE infrastructure using:
- **Packer** for template creation (Ubuntu 24.04 LTS, Debian Trixie)  
- **Terraform** for VM provisioning and infrastructure management
- **Makefile** for automation and workflow orchestration
- **Cloud-Init** for automated VM configuration

## Tool Usage Reminders
- Always use specialized agents (Task tool) when the task matches an agent's description
- Use MCP tools when available, as they may have fewer restrictions than built-in tools  
- Be proactive in using the most appropriate tool for each task

## Important Instructions
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## Project Structure
```
/home/matteo/Homelab/
├── .gitignore              # Git ignore rules (consolidated)
├── CLAUDE.md              # This file - Claude instructions
├── README.md              # Project documentation
├── LICENSE                # MIT License
├── Makefile               # Build automation
├── packer/                # Packer templates and configs
│   ├── credentials.pkr.hcl       # Proxmox API credentials
│   ├── ubuntu-server-noble/      # Ubuntu 24.04 LTS template
│   └── debian-server-trixie/     # Debian Trixie template
└── terraform/             # Terraform infrastructure configs
    ├── main.tf            # Main infrastructure definition
    ├── variables.tf       # Variable definitions
    ├── outputs.tf         # Output definitions
    └── terraform.tfvars   # Variable values (ignored by git)
```

## Key Commands Available
From the Makefile, the following commands are available:
- `make check` - Verify prerequisites
- `make build-all` - Build all Packer templates
- `make build-ubuntu` - Build Ubuntu template
- `make build-debian-trixie` - Build Debian template  
- `make terraform-init` - Initialize Terraform
- `make terraform-plan` - Plan Terraform changes
- `make terraform-apply` - Apply Terraform configuration
- `make terraform-destroy` - Destroy infrastructure
- `make clean-packer` - Clean Packer cache
- `make help` - Show all available commands

## Git Configuration
- **Main branch**: `main` (for production/stable changes)
- **Development branch**: `dev` (for development work)
- **Gitignore**: Consolidated in root, covers Proxmox credentials, SSH keys, Terraform state, temporary files, and all standard ignore patterns

## Security Considerations
- Proxmox API credentials in `packer/credentials.pkr.hcl` (ignored by git)
- SSH keys (*.pem, *.pub, id_rsa*) are ignored by git
- Terraform state files and variables are ignored by git
- All sensitive files are properly excluded from version control

## When Working on This Project
1. Always check current git status and branch
2. Use appropriate make commands for building and deploying
3. Respect the existing project structure and conventions
4. Follow Infrastructure as Code principles
5. Test changes in dev branch before merging to main