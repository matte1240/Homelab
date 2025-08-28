# Terraform - Debian VM per Proxmox VE

Configurazione Terraform per creare una VM Debian con cloud-init su Proxmox VE.

## 🚀 Quick Start

1. **Copia e configura le variabili**:
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   nano terraform.tfvars
   ```

2. **Inizializza Terraform**:
   ```bash
   terraform init
   ```

3. **Pianifica la creazione**:
   ```bash
   terraform plan
   ```

4. **Crea la VM**:
   ```bash
   terraform apply
   ```

5. **Distruggi la VM** (quando non serve più):
   ```bash
   terraform destroy
   ```

## ⚙️ Configurazione

### Variabili Principali

| Variabile | Descrizione | Default |
|-----------|-------------|---------|
| `proxmox_api_url` | URL API Proxmox | - |
| `proxmox_user` | Utente Proxmox | - |
| `proxmox_password` | Password Proxmox | - |
| `vm_name` | Nome della VM | `debian-vm` |
| `vm_cores` | Numero CPU cores | `2` |
| `vm_memory` | RAM in MB | `2048` |
| `template_name` | Template da clonare | `debian-server-trixie-template` |

### Cloud-Init

La configurazione cloud-init è gestita tramite template e include:

- Creazione utente con sudo
- Configurazione SSH keys
- Installazione pacchetti
- Configurazione timezone/locale
- Abilitazione servizi

### Esempio terraform.tfvars (adattato al tuo ambiente)

```hcl
# Connessione Proxmox (usa i token API invece delle password)
proxmox_api_url  = "https://YOUR_PROXMOX_IP:8006/api2/json"
proxmox_username = "YOUR_USERNAME@pam!YOUR_TOKEN_ID"
proxmox_password = "YOUR_TOKEN_SECRET"

# Configurazione VM (specs dal tuo template Packer)
vm_name       = "my-debian-vm"
vm_cores      = 4                                    # Dal tuo Packer
vm_memory     = 4096                                 # Dal tuo Packer
disk_size     = "25G"                               # Dal tuo Packer
storage_pool  = "data"                              # Dal tuo Packer
template_name = "debian-server-trixie-template"     # Creato con Packer

# Cloud-init (con la tua chiave SSH esistente)
ci_user = "debian"
ssh_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCa7rARd0MiXcM+/FFMk3hpNlThZ..."

# IP statico (adattato alla tua rete 192.168.178.x)
ip_config = {
  ip      = "192.168.178.100/24"                    # Adatta alla tua rete
  gateway = "192.168.178.1"
}
```

## 📋 Prerequisiti

- Terraform >= 1.0
- Template Debian già creato su Proxmox (usa Packer dal progetto)
- Credenziali API Proxmox configurate

## 🔧 Personalizzazione

### Aggiungere pacchetti

Nel file `terraform.tfvars`:
```hcl
packages = [
  "qemu-guest-agent",
  "sudo",
  "curl",
  "docker.io",
  "nginx"
]
```

### Comandi personalizzati

```hcl
run_commands = [
  "systemctl enable qemu-guest-agent",
  "systemctl start qemu-guest-agent",
  "docker --version"
]
```

## 📁 Struttura File

```
terraform/
├── main.tf                 # Configurazione principale
├── variables.tf            # Definizione variabili
├── cloud-init.tf          # Configurazione cloud-init
├── cloud-init.yaml.tpl    # Template cloud-init
├── outputs.tf             # Output values
├── terraform.tfvars.example # Esempio configurazione
└── README.md              # Questa documentazione
```

## 🐛 Troubleshooting

### VM ID già esistente
Cambia `vm_id` nel file `terraform.tfvars` o rimuovi la VM esistente.

### Errore connessione API
Verifica URL, credenziali e certificati SSL in `terraform.tfvars`.

### Template non trovato
Assicurati che il template specificato in `template_name` esista su Proxmox.