# Gestione Proxmox VE con Ansible

Questo documento descrive come utilizzare gli script Ansible per gestire e aggiornare il server Proxmox VE.

## 📋 Panoramica

Gli script forniscono le seguenti funzionalità:

- **Aggiornamento completo** con backup e riavvio automatico
- **Aggiornamento rapido** senza riavvio
- **Manutenzione e pulizia** del sistema
- **Monitoraggio dello stato** dei servizi

## 🚀 Utilizzo Rapido

### Menu Principale
```bash
make proxmox-menu
```

### Comandi Principali
```bash
# Controllo stato
make proxmox-status

# Aggiornamento rapido (senza riavvio)
make proxmox-quick-update

# Aggiornamento completo (con riavvio)
make proxmox-update

# Manutenzione e pulizia
make proxmox-maintenance

# Test connettività
make proxmox-ping
```

## 📁 Struttura File

```
ansible/
├── inventories/
│   └── proxmox/
│       ├── hosts                    # Inventory Proxmox
│       └── group_vars/
│           └── all.yml             # Configurazioni Proxmox
├── playbooks/
│   ├── proxmox-update.yml          # Aggiornamento completo
│   ├── proxmox-quick-update.yml    # Aggiornamento rapido
│   ├── proxmox-maintenance.yml     # Manutenzione
│   └── proxmox-management.yml      # Gestione generale
└── secrets.yml                     # Credenziali (configurare)
```

## ⚙️ Configurazione

### 1. Inventario Proxmox

Il file `inventories/proxmox/hosts` contiene:

```ini
[proxmox]
pve-01 ansible_host=192.168.178.70 ansible_user=root

[proxmox:vars]
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
environment=proxmox
```

### 2. Configurazioni

Il file `inventories/proxmox/group_vars/all.yml` contiene:

```yaml
# Environment specific settings
env_name: proxmox
target_env: proxmox

# Proxmox specific settings
proxmox_version_check: true
proxmox_backup_before_update: true
proxmox_reboot_after_update: true
proxmox_wait_for_reboot: true
proxmox_update_timeout: 1800  # 30 minutes
proxmox_reboot_timeout: 600   # 10 minutes

# Update options
update_no_subscription: true  # Set to true if using Proxmox without subscription
update_enterprise: false     # Set to true if you have Proxmox VE Enterprise subscription
test_repositories: false     # Set to true to enable test repositories

# Services to check after update
services_to_check:
  - pveproxy
  - pvedaemon
  - pvestatd
  - pve-cluster
  - corosync
  - pve-firewall
```

### 3. Credenziali SSH

Assicurati di avere configurato l'accesso SSH al server Proxmox:

```bash
# Genera chiave SSH se non esiste
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Copia la chiave sul server Proxmox
ssh-copy-id root@192.168.178.70

# Test connessione
ssh root@192.168.178.70
```

## 🔄 Operazioni di Aggiornamento

### Aggiornamento Completo

```bash
make proxmox-update
```

**Cosa fa:**
- ✅ Backup della configurazione in `/var/backups/proxmox-updates/`
- ✅ Configurazione repository (no-subscription)
- ✅ Aggiornamento di tutti i pacchetti
- ✅ Riavvio automatico se necessario
- ✅ Verifica servizi post-riavvio
- ✅ Log dettagliato in `/var/log/proxmox-updates/`

### Aggiornamento Rapido

```bash
make proxmox-quick-update
```

**Cosa fa:**
- ✅ Aggiornamento pacchetti (escluso kernel)
- ✅ Nessun riavvio automatico
- ✅ Indicazione se riavvio necessario
- ✅ Più veloce e sicuro per aggiornamenti minori

### Manutenzione

```bash
make proxmox-maintenance
```

**Cosa fa:**
- 🧹 Pulizia log files vecchi
- 🧹 Rimozione kernel obsoleti
- 🧹 Pulizia backup VM vecchi
- 🧹 Pulizia package cache
- 📊 Report storage usage
- 📊 Status cluster e servizi

## 📊 Monitoraggio

### Status Completo

```bash
make proxmox-status
```

**Informazioni mostrate:**
- 📋 Versione Proxmox corrente
- ⏰ Uptime sistema
- 💾 Utilizzo disco
- 📦 Aggiornamenti disponibili
- 🔄 Stato riavvio richiesto
- 🏃 VM/Container in esecuzione
- 🌐 URL interfaccia web

### Test Connettività

```bash
make proxmox-ping
```

Verifica che Ansible possa raggiungere il server Proxmox.

## 📁 File di Log e Backup

### Log di Aggiornamento
```
/var/log/proxmox-updates/
├── proxmox-update-1694123456.log
├── proxmox-update-1694123789.log
└── ...
```

### Backup Configurazione
```
/var/backups/proxmox-updates/
├── proxmox-config-backup-1694123456.tar.gz
├── proxmox-config-backup-1694123789.tar.gz
└── ...
```

I backup includono:
- `/etc/pve/` - Configurazione cluster Proxmox
- `/etc/network/interfaces` - Configurazione rete
- `/etc/hosts`, `/etc/hostname`, `/etc/resolv.conf`

## 🔧 Personalizzazione

### Modifica Configurazioni

Edita `inventories/proxmox/group_vars/all.yml`:

```yaml
# Disabilita backup automatico
proxmox_backup_before_update: false

# Disabilita riavvio automatico
proxmox_reboot_after_update: false

# Cambia timeout
proxmox_update_timeout: 3600  # 1 ora
proxmox_reboot_timeout: 900   # 15 minuti

# Abilita repository test (non raccomandato per produzione)
test_repositories: true
```

### Servizi Personalizzati

Aggiungi servizi da controllare:

```yaml
services_to_check:
  - pveproxy
  - pvedaemon
  - pvestatd
  - pve-cluster
  - corosync
  - pve-firewall
  - custom-service  # Tuo servizio personalizzato
```

## 🚨 Sicurezza e Best Practice

### Backup Prima degli Aggiornamenti

**Sempre eseguire backup completo prima di aggiornamenti maggiori:**

```bash
# Dal server Proxmox
vzdump --mode suspend --compress gzip --all --storage local
```

### Repository Configuration

**Per sistemi di produzione:**
- Usa repository enterprise se hai sottoscrizione
- Testa aggiornamenti in ambiente di sviluppo
- Pianifica finestre di manutenzione

**Configurazione subscription:**

```yaml
# In group_vars/all.yml
update_no_subscription: false
update_enterprise: true
```

### Monitoraggio Post-Aggiornamento

Dopo ogni aggiornamento, verifica:

```bash
# Status servizi
systemctl status pveproxy pvedaemon pvestatd

# Log errori
journalctl -u pveproxy -f

# Web interface
https://192.168.178.70:8006
```

## 📞 Troubleshooting

### Problemi Comuni

**1. Connessione SSH fallita**
```bash
# Verifica connettività
ping 192.168.178.70

# Test SSH manuale
ssh -v root@192.168.178.70

# Controlla chiavi SSH
ssh-keygen -R 192.168.178.70
ssh-copy-id root@192.168.178.70
```

**2. Repository errors**
```bash
# Sul server Proxmox, controlla repository
cat /etc/apt/sources.list.d/pve-*.list

# Aggiorna chiavi APT
apt-get update --allow-releaseinfo-change
```

**3. Servizi non avviati dopo riavvio**
```bash
# Controlla status
systemctl status pveproxy pvedaemon

# Restart manuale
systemctl restart pveproxy pvedaemon pvestatd

# Log dettagliati
journalctl -u pveproxy -n 50
```

### Recovery

**Se l'aggiornamento fallisce:**

1. **Ripristina backup configurazione:**
   ```bash
   cd /var/backups/proxmox-updates/
   tar -xzf proxmox-config-backup-TIMESTAMP.tar.gz -C /
   ```

2. **Riavvia servizi:**
   ```bash
   systemctl restart pveproxy pvedaemon pvestatd
   ```

3. **Verifica stato cluster:**
   ```bash
   pvecm status
   ```

## 📝 Esempi d'Uso Completi

### Aggiornamento Mensile

```bash
# 1. Controlla stato attuale
make proxmox-status

# 2. Esegui manutenzione
make proxmox-maintenance

# 3. Aggiornamento completo
make proxmox-update

# 4. Verifica post-aggiornamento
make proxmox-status
```

### Aggiornamento Emergenza

```bash
# Solo pacchetti critici, senza riavvio
make proxmox-quick-update

# Controlla se riavvio necessario
make proxmox-status

# Se necessario, riavvio manuale programmato
# make proxmox-update
```

### Manutenzione Settimanale

```bash
# Solo pulizia e controlli
make proxmox-maintenance
```

## 🔗 Link Utili

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox VE Package Repositories](https://pve.proxmox.com/wiki/Package_Repositories)
- [Ansible Documentation](https://docs.ansible.com/)

---

**⚠️ Nota:** Testa sempre gli script in ambiente di sviluppo prima dell'uso in produzione!