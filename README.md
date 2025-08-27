# Ubuntu Server Template per Proxmox VE

Template Packer per creare un template Ubuntu Server 24.04 LTS (Noble) ottimizzato per Proxmox VE con Cloud-Init.

## ✨ Caratteristiche

- **Ubuntu Server 24.04 LTS** (Noble Numbat)
- **Cloud-Init integrato** per Proxmox VE
- **Autenticazione SSH con chiavi** per maggiore sicurezza
- **Template ottimizzato** con cleanup automatico
- **Build veloce** (6-7 minuti) con risorse potenziate

## 🚀 Quick Start

1. **Clona il repository**:
   ```bash
   git clone https://github.com/matte1240/Homelab.git
   cd Homelab
   ```

2. **Verifica prerequisiti e configurazione**:
   ```bash
   make check
   ```

3. **Configura le credenziali Proxmox** (se non già fatto):
   ```bash
   cp credentials.pkr.hcl.example credentials.pkr.hcl
   nano credentials.pkr.hcl
   ```

4. **Genera chiavi SSH** (se non già fatto):
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "ubuntu@packer-build"
   ```

5. **Costruisci i template**:
   ```bash
   # Tutti i template
   make build-all
   
   # Solo Ubuntu
   make build-ubuntu
   
   # Solo Debian Trixie
   make build-debian-trixie
   ```

6. **Mostra aiuto completo**:
   ```bash
   make help
   ```

## 📋 Prerequisiti

- **Proxmox VE** 7.0 o superiore
- **Packer** 1.8 o superiore
- **Plugin Proxmox** v1.2.3+ (con supporto `iso_download_pve`)
- **Credenziali API** Proxmox configurate

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

📖 **Documentazione completa**: [ISO_DOWNLOAD.md](ubuntu-server-noble/ISO_DOWNLOAD.md)

## ⚙️ Configurazione

### Specifiche Template
- **VM ID**: 901
- **Nome**: ubuntu-server-noble-template
- **CPU**: 4 cores
- **RAM**: 4GB
- **Disco**: 25GB (formato raw)
- **Rete**: virtio su vmbr0
- **Storage**: pool `data`

### File Principali
- `credentials.pkr.hcl` - Credenziali API Proxmox
- `ubuntu-server-noble.pkr.hcl` - Configurazione template principale
- `http/user-data` - Configurazione Cloud-Init/Autoinstall
- `http/meta-data` - Metadati Cloud-Init
- `files/99-pve.cfg` - Configurazione datasource Cloud-Init per Proxmox

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
├── credentials.pkr.hcl              # Credenziali Proxmox
├── README.md                        # Documentazione
└── ubuntu-server-noble/
    ├── files/
    │   └── 99-pve.cfg              # Config Cloud-Init
    ├── http/
    │   ├── meta-data               # Metadati
    │   └── user-data               # Autoinstall config
    ├── plugins.pkr.hcl             # Plugin Packer
    └── ubuntu-server-noble.pkr.hcl  # Template principale
```

## 🔐 Sicurezza

- **Autenticazione SSH**: Solo chiavi, password disabilitata per root
- **Utente sudo**: `ubuntu` con accesso completo
- **Firewall**: Configurabile via Cloud-Init
- **Updates**: Aggiornamenti gestiti via Cloud-Init

## 🐛 Troubleshooting

### Build fallisce con "VM already exists"
```bash
# Cambia VM ID nel file .pkr.hcl oppure rimuovi la VM esistente da Proxmox
```

### Timeout SSH dopo reboot
- Verificare che la chiave SSH sia corretta nel file `user-data`
- Controllare che il file `~/.ssh/id_rsa` esista

### Template non funziona con Cloud-Init
- Verificare che il file `99-pve.cfg` sia stato copiato correttamente
- Controllare la configurazione datasource in Proxmox

## 📝 Licenza

MIT License - Vedi file LICENSE per dettagli.

## 🤝 Contributi

Contributi, issue e feature request sono benvenuti!
