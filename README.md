# Homelab Infrastructure as Code

Repository completo per la gestione di un homelab basato su **Proxmox VE** utilizzando **Infrastructure as Code** con Packer e Terraform.

## ✨ Caratteristiche

- **Template Packer** per Ubuntu Server 24.04 LTS e Debian Trixie
- **Provisioning Terraform** per creazione VM automatizzata
- **Cloud-Init integrato** per configurazione automatica
- **Autenticazione SSH sicura** con chiavi
- **Build ottimizzati** e pulizia automatica
- **Makefile** per automazione completa

## 🚀 Quick Start

1. **Clona il repository**:
   ```bash
   git clone https://github.com/matte1240/Homelab.git
   cd Homelab
   ```

2. **Verifica prerequisiti**:
   ```bash
   make check
   ```

3. **Configura credenziali**:
   ```bash
   # Packer
   cp packer/credentials.pkr.hcl.example packer/credentials.pkr.hcl
   nano packer/credentials.pkr.hcl
   
   # Terraform
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   nano terraform/terraform.tfvars
   ```

4. **Genera chiavi SSH**:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "homelab@packer-build"
   ```

5. **Costruisci template e provisiona VM**:
   ```bash
   # Costruisci tutti i template Packer
   make build-all
   
   # Provisiona VM con Terraform
   make terraform-apply
   ```

6. **Mostra aiuto completo**:
   ```bash
   make help
   ```

## 📋 Prerequisiti

- **Proxmox VE** 7.0 o superiore
- **Packer** 1.8 o superiore
- **Terraform** 1.0 o superiore
- **Provider Proxmox** per Terraform (bpg/proxmox ~> 0.66)
- **Plugin Proxmox** per Packer v1.2.3+
- **Credenziali API** Proxmox configurate

## �️ Packer - Template Creation

### Template Disponibili

#### Ubuntu Server 24.04 LTS (Noble)
- **VM ID**: 901
- **Nome**: ubuntu-server-noble-template
- **Build time**: ~6-7 minuti
- **Caratteristiche**: Download ISO automatico, Cloud-Init integrato

#### Debian Trixie (Testing)
- **VM ID**: 902
- **Nome**: debian-server-trixie-template
- **Build time**: ~8-10 minuti
- **Caratteristiche**: Versione rolling, pacchetti aggiornati

### Comandi Packer
```bash
# Costruisci tutti i template
make build-all

# Costruisci solo Ubuntu
make build-ubuntu

# Costruisci solo Debian
make build-debian-trixie

# Pulisci cache Packer
make clean-packer
```

## 🌐 Terraform - VM Provisioning

Terraform automatizza la creazione di VM dal template Packer, configurando rete, risorse e Cloud-Init.

### Caratteristiche Terraform
- **Provider Proxmox** ufficiale (bpg/proxmox)
- **Clonazione da template** Packer
- **Configurazione Cloud-Init** automatica
- **Gestione stato** sicura con backend locale
- **Variabili configurabili** per personalizzazione

### Comandi Terraform
```bash
# Inizializza Terraform
make terraform-init

# Pianifica modifiche
make terraform-plan

# Applica configurazione
make terraform-apply

# Distruggi risorse
make terraform-destroy

# Mostra stato
make terraform-show
```

### Configurazione Terraform
Modifica `terraform/terraform.tfvars`:
```hcl
# Proxmox connection
proxmox_api_url = "https://proxmox.example.com:8006/api2/json"
proxmox_token_id = "terraform@pve!terraform"
proxmox_token_secret = "your-token-secret"

# VM configuration
vm_name = "debian-homelab"
vm_id = 100
proxmox_node = "pve"
vm_cores = 2
vm_memory = 2048
network_bridge = "vmbr0"
```

## ⚙️ Configurazione

### Specifiche Template

#### Ubuntu Server 24.04 LTS
- **VM ID**: 901
- **Nome**: ubuntu-server-noble-template
- **CPU**: 4 cores
- **RAM**: 4GB
- **Disco**: 25GB (formato raw)
- **Rete**: virtio su vmbr0
- **Storage**: pool `data`

#### Debian Trixie
- **VM ID**: 902
- **Nome**: debian-server-trixie-template
- **CPU**: 2 cores
- **RAM**: 2GB
- **Disco**: 20GB (formato raw)
- **Rete**: virtio su vmbr0
- **Storage**: pool `data`

### File Principali
- `packer/credentials.pkr.hcl` - Credenziali API Proxmox per Packer
- `terraform/terraform.tfvars` - Variabili Terraform
- `packer/ubuntu-server-noble/` - Template Ubuntu
- `packer/debian-server-trixie/` - Template Debian
- `terraform/main.tf` - Configurazione Terraform principale

## 🔧 Personalizzazione

### Modificare risorse VM
Nel file `ubuntu-server-noble.pkr.hcl`:
```hcl
cores = "2"           # CPU cores
memory = "2048"       # RAM in MB
disk_size = "20G"     # Dimensione disco
```

### Aggiungere pacchetti
Nel file `http/user-data`:
```yaml
packages:
  - qemu-guest-agent
  - sudo
  - curl
  - wget
  - openssh-server
  - htop              # Aggiungi qui
  - vim               # Altri pacchetti
```

### Configurare rete statica
Nel file `http/user-data`:
```yaml
network:
  network:
    version: 2
    ethernets:
      ens18:
        addresses: [192.168.1.100/24]
        gateway4: 192.168.1.1
        nameservers:
          addresses: [8.8.8.8, 8.8.4.4]
```

## 📁 Struttura Progetto

```
├── .gitignore                    # File ignorati da Git
├── LICENSE                       # Licenza MIT
├── Makefile                      # Automazione build e deploy
├── README.md                     # Questa documentazione
├── packer/
│   ├── credentials.pkr.hcl       # Credenziali Proxmox per Packer
│   ├── credentials.pkr.hcl.example
│   ├── debian-server-trixie/
│   │   ├── debian-server-trixie.pkr.hcl
│   │   ├── plugins.pkr.hcl
│   │   ├── files/
│   │   │   └── 99-pve.cfg       # Config Cloud-Init
│   │   └── http/
│   │       ├── meta-data         # Metadati Cloud-Init
│   │       └── user-data         # Autoinstall config
│   └── ubuntu-server-noble/
│       ├── ubuntu-server-noble.pkr.hcl
│       ├── plugins.pkr.hcl
│       ├── files/
│       │   └── 99-pve.cfg       # Config Cloud-Init
│       └── http/
│           ├── meta-data         # Metadati Cloud-Init
│           └── user-data         # Autoinstall config
└── terraform/
    ├── main.tf                  # Configurazione VM principale
    ├── outputs.tf               # Output Terraform
    ├── variables.tf             # Definizioni variabili
    ├── terraform.tfvars         # Valori variabili
    ├── terraform.tfvars.example
    └── terraform.tfstate*       # Stato Terraform (ignorato)
```

## 🆕 Nuove Funzionalità

### 📥 Download Automatico ISO (v1.1.7+)
Il template ora supporta il **download automatico delle ISO direttamente sul nodo Proxmox**, eliminando la necessità di upload manuale:

```hcl
boot_iso {
    iso_url          = "https://releases.ubuntu.com/24.04.3/ubuntu-24.04.3-live-server-amd64.iso"
    iso_storage_pool = "local"
    iso_download_pve = true        # 🔑 Download automatico!
}
```

**Vantaggi**:
- ⚡ **Build più veloci** - nessun upload da Packer a Proxmox
- 🌐 **Efficienza di rete** - download diretto sul nodo
- 🔄 **Automazione completa** - nessuna gestione manuale ISO

📖 **Documentazione completa**: [packer/ubuntu-server-noble/ISO_DOWNLOAD.md](packer/ubuntu-server-noble/ISO_DOWNLOAD.md)

### 🔄 Infrastructure as Code Completo
- **Packer + Terraform** integrazione completa
- **Workflow automatizzato** dal template alla VM
- **Configurazione dichiarativa** per tutto l'homelab
- **Versionamento** di infrastruttura e configurazione

## 🔐 Sicurezza

- **Autenticazione SSH**: Solo chiavi, password disabilitata per root
- **Utente sudo**: `ubuntu` con accesso completo
- **Firewall**: Configurabile via Cloud-Init
- **Updates**: Aggiornamenti gestiti via Cloud-Init

## 🐛 Troubleshooting

### Packer Issues

#### Build fallisce con "VM already exists"
```bash
# Cambia VM ID nel file .pkr.hcl oppure rimuovi la VM esistente da Proxmox
```

#### Timeout SSH dopo reboot
- Verificare che la chiave SSH sia corretta nel file `user-data`
- Controllare che il file `~/.ssh/id_rsa` esista

#### Template non funziona con Cloud-Init
- Verificare che il file `99-pve.cfg` sia stato copiato correttamente
- Controllare la configurazione datasource in Proxmox

### Terraform Issues

#### Errore "template not found"
- Assicurati che il template Packer sia stato creato con successo
- Verifica che il VM ID nel `main.tf` corrisponda al template (902 per Debian)

#### Errore connessione Proxmox
- Verifica le credenziali in `terraform.tfvars`
- Controlla che l'endpoint API sia corretto e accessibile
- Assicurati che il token API abbia i permessi necessari

#### VM non si avvia dopo terraform apply
- Verifica la configurazione Cloud-Init nella VM
- Controlla i log di Proxmox per errori di avvio
- Assicurati che la rete sia configurata correttamente

#### Stato Terraform corrotto
```bash
# Rimuovi lo stato e reinizializza
rm terraform.tfstate*
terraform init
```

## 📝 Licenza

MIT License - Vedi file LICENSE per dettagli.

## 🤝 Contributi

Contributi, issue e feature request sono benvenuti!
