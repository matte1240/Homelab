# Gestione Proxmox VE tramite API REST

Questa guida descrive come utilizzare le API REST di Proxmox VE per gestire e aggiornare il server in modo più sicuro ed efficiente rispetto all'accesso SSH tradizionale.

## 🌟 Vantaggi dell'API REST

### ✅ Sicurezza
- **Nessun accesso SSH root** richiesto
- **Token API dedicati** con permessi specifici
- **Autenticazione sicura** tramite token
- **Log audit** completo di tutte le operazioni

### ✅ Funzionalità
- **Monitoraggio in tempo reale** dei task
- **Accesso completo** a tutte le funzionalità Proxmox
- **Gestione VMs/Containers** integrata
- **Storage management** avanzato
- **Cluster management** (se applicabile)

### ✅ Affidabilità
- **Gestione errori** migliorata
- **Timeout configurabili** per operazioni lunghe
- **Retry automatico** per operazioni fallite
- **Logging dettagliato** delle operazioni

## 🚀 Setup Rapido

### 1. Configurazione Iniziale
```bash
# Setup guidato delle API
make proxmox-api-setup
```

Questo script ti guiderà attraverso:
- Creazione del token API su Proxmox
- Configurazione delle credenziali
- Test di connettività
- Verifica dei permessi

### 2. Test Configurazione
```bash
# Verifica status via API
make proxmox-api-status
```

### 3. Primo Aggiornamento
```bash
# Aggiornamento completo via API
make proxmox-api-update
```

## 📋 Comandi Disponibili

### Management Generale
```bash
make proxmox-menu              # Menu principale con tutte le opzioni
make proxmox-api-setup         # Setup iniziale API
make proxmox-api-status        # Status completo del sistema
```

### Aggiornamenti
```bash
make proxmox-api-update        # Aggiornamento completo con riavvio
make proxmox-api-maintenance   # Manutenzione e pulizia sistema
```

### Monitoraggio
```bash
make proxmox-api-vms           # Lista VMs e containers
make proxmox-api-storage       # Status storage e utilizzo
make proxmox-api-tasks         # Task attivi e recenti
make proxmox-api-cluster       # Status cluster (se presente)
```

### Automazione
```bash
make proxmox-api-test-auto-update  # Test script automatico
```

## 🔧 Configurazione Dettagliata

### Token API Proxmox

1. **Accedi a Proxmox Web UI**
   ```
   https://192.168.178.70:8006
   ```

2. **Naviga in:**
   ```
   Datacenter -> Permissions -> API Tokens
   ```

3. **Crea nuovo token:**
   - User: `root@pam`
   - Token ID: `automation`
   - Comment: `Ansible automation token`
   - **Privilege Separation: NO** (importante!)

4. **Copia il Token Secret** (mostrato solo una volta!)

### File di Configurazione

Le credenziali vengono salvate in `ansible/secrets.yml`:

```yaml
# Proxmox API credentials
vault_proxmox_api_url: "https://192.168.178.70:8006/api2/json"
vault_proxmox_api_user: "root@pam"
vault_proxmox_api_password: "your_root_password"
vault_proxmox_api_token_id: "root@pam!automation"
vault_proxmox_api_token_secret: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
vault_proxmox_node: "pve"
```

## 📊 Output di Esempio

### Status Completo
```
📊 PROXMOX VE API STATUS REPORT
════════════════════════════════
🖥️  Node: pve
🌐 API URL: https://192.168.178.70:8006/api2/json
📦 Version: proxmox-ve: 8.0.4 (running kernel: 6.2.16-3-pve)
⏰ Uptime: 5d 12h 34m
🔧 Status: online

💾 RESOURCES:
   CPU: 15.2% (8 cores)
   Memory: 23.4% (15.8GB / 64GB)
   Root FS: 45.2% (125GB available)

📦 UPDATES:
   Available: 3

🔄 ACTIVE TASKS:
   Running: 0
   Total tasks: 25
```

### Lista VMs
```
🖥️  VIRTUAL MACHINES (3):
   100: Ubuntu-Web - running (4GB RAM)
   101: Ubuntu-DB - running (8GB RAM)
   102: Windows-Test - stopped (2GB RAM)

📦 CONTAINERS (2):
   200: nginx-proxy - running (512MB RAM)
   201: monitoring - running (1GB RAM)
```

## 🔄 Processo di Aggiornamento

### Aggiornamento Completo
```bash
make proxmox-api-update
```

**Fasi dell'aggiornamento:**
1. ✅ Test connettività API
2. ✅ Verifica versione corrente
3. ✅ Controllo aggiornamenti disponibili
4. ✅ Refresh database pacchetti
5. ✅ Esecuzione upgrade con monitoraggio
6. ✅ Verifica necessità riavvio
7. ✅ Riavvio automatico (se necessario)
8. ✅ Verifica post-riavvio
9. ✅ Status finale

### Monitoraggio Task
L'API permette di monitorare il progresso delle operazioni:
```
Upgrade task status: running
Progress: 45%
Current operation: Installing kernel updates...
```

## 🛠️ Troubleshooting

### Problemi Comuni

**1. Token API non funziona**
```bash
# Verifica configurazione
make proxmox-api-setup

# Test manuale
curl -k -H "Authorization: PVEAPIToken=root@pam!automation=your-secret" \
  https://192.168.178.70:8006/api2/json/version
```

**2. Permessi insufficienti**
- Assicurati che "Privilege Separation" sia **disabilitato**
- Verifica che l'utente abbia permessi di amministratore

**3. Errori di connessione**
```bash
# Test connettività base
ping 192.168.178.70
curl -k https://192.168.178.70:8006

# Verifica certificati
openssl s_client -connect 192.168.178.70:8006
```

**4. Task bloccati**
```bash
# Monitora task attivi
make proxmox-api-tasks

# Cancella task se necessario (da web UI)
```

### Log e Debug

**Log delle operazioni:**
```bash
# Log aggiornamenti API
tail -f /tmp/proxmox-api-updates/proxmox-api-update-*.log

# Debug Ansible
cd ansible
ansible-playbook playbooks/proxmox-api-update.yml -v
```

## 🤖 Automazione

### Script Automatico
Il sistema include uno script per aggiornamenti automatici via API:

```bash
# Test manuale
sudo /home/matteo/Homelab/ansible/scripts/proxmox-api-auto-update.sh

# Setup cron automatico
# (Modifica lo script proxmox-auto-update.cron per usare la versione API)
```

### Logica Aggiornamenti
- **1° del mese**: Aggiornamento completo con riavvio
- **Lunedì**: Manutenzione settimanale
- **Altri giorni**: Controllo aggiornamenti rapidi

## 🔗 API Reference

### Endpoint Principali
```
GET  /api2/json/version                    # Versione sistema
GET  /api2/json/nodes/{node}/status        # Status nodo
GET  /api2/json/nodes/{node}/apt/update    # Lista aggiornamenti
POST /api2/json/nodes/{node}/apt/update    # Refresh database
POST /api2/json/nodes/{node}/apt/upgrade   # Esegui upgrade
GET  /api2/json/nodes/{node}/tasks         # Lista task
GET  /api2/json/nodes/{node}/qemu          # Lista VMs
GET  /api2/json/nodes/{node}/lxc           # Lista containers
GET  /api2/json/nodes/{node}/storage       # Status storage
```

### Autenticazione
```bash
# Con token (raccomandato)
Authorization: PVEAPIToken=USER@REALM!TOKENID=SECRET

# Con username/password (legacy)
username=root@pam&password=yourpassword
```

## 📚 Risorse Aggiuntive

- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Proxmox REST API Guide](https://pve.proxmox.com/wiki/Proxmox_VE_API)
- [Python Proxmoxer Library](https://github.com/proxmoxer/proxmoxer)

---

**🎯 Raccomandazione:** Usa sempre l'API invece di SSH per la gestione automatizzata di Proxmox. È più sicuro, affidabile e offre funzionalità superiori.