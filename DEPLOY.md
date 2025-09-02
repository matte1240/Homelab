# 🚀 Deploy Automatizzato Homelab

## Panoramica

Il Makefile ora include una funzione di **deploy automatizzato completo** che gestisce automaticamente:

1. **🏗️ Template Packer**: Verifica presenza su Proxmox e crea se necessario
2. **💻 VM Terraform**: Controlla stato e crea/aggiorna le VM
3. **⚙️ Configurazione Ansible**: Deploy completo o incrementale dei servizi

## 🎯 Uso Rapido

### Deploy Completo Automatizzato
```bash
make deploy-complete
```

Questo comando eseguirà automaticamente tutti i passaggi necessari per avere l'homelab funzionante!

### Controllo Status
```bash
make status-all
```

Mostra lo stato completo di template, VM e servizi.

## 📋 Comandi Principali

### Deploy e Setup
| Comando | Descrizione |
|---------|-------------|
| `make deploy-complete` | Deploy automatizzato completo |
| `make check-templates` | Verifica template Packer su Proxmox |
| `make ensure-templates` | Garantisce presenza template necessari |
| `make terraform-check-and-apply` | Gestione intelligente VM Terraform |
| `make ansible-deploy-smart` | Deploy Ansible completo o incrementale |

### Monitoraggio
| Comando | Descrizione |
|---------|-------------|
| `make status-all` | Status completo homelab |
| `make test-connectivity` | Test connettività completo |
| `make logs-services` | Logs servizi Docker |

### Troubleshooting
| Comando | Descrizione |
|---------|-------------|
| `make reset-all` | Reset completo (DISTRUTTIVO!) |
| `make clean-all` | Pulizia file temporanei |

## 🔄 Flusso di Deploy Automatizzato

### Fase 1: Template Packer
- ✅ Controlla presenza template Ubuntu (ID 900) su Proxmox
- 🏗️ Se mancante, lo crea automaticamente
- ⚡ Se presente, procede direttamente

### Fase 2: Infrastruttura Terraform
- 🔍 Verifica inizializzazione Terraform
- 📊 Controlla stato attuale delle VM
- 🆕 Se assenti, crea le VM
- 🔄 Se presenti ma non aggiornate, applica modifiche
- ✅ Se aggiornate, procede

### Fase 3: Configurazione Ansible
- 🏓 Testa connettività alle VM
- 📦 Se primo deploy, esegue configurazione completa
- 🔄 Se deploy precedente, mostra diff e chiede conferma
- ⏱️ Gestisce automaticamente i tempi di attesa per boot VM

## 🎛️ Configurazioni Intelligenti

### Template Check
Il sistema può rilevare i template su Proxmox in tre modi (in ordine di precisione):
1. **Comando `pvesh`** (se disponibile): Controllo diretto via shell Proxmox
2. **API REST** (se credenziali disponibili): Controllo via API HTTP con token
3. **Ping + Assunzione**: Se Proxmox è raggiungibile, assume template presente

### Terraform Smart Apply
- **Zero VM**: Crea tutto da zero
- **VM esistenti**: Controlla differenze e applica solo se necessario
- **Errori**: Gestisce gracefully con rollback

### Ansible Incremental Deploy
- **Primo deploy**: Configurazione completa
- **Deploy successivi**: Solo modifiche necessarie con anteprima
- **Connettività**: Attesa automatica per boot VM

## 🔧 Personalizzazione

### Variabili Principali
```makefile
# Timeout per boot VM (default: 30s)
VM_BOOT_TIMEOUT := 30

# ID template Ubuntu (legge da terraform.tfvars)
UBUNTU_TEMPLATE_ID := 900

# Host Proxmox (legge da terraform.tfvars)
PROXMOX_HOST := 192.168.178.70
```

### File di Stato
Il sistema usa file temporanei per tracciare lo stato:
- `/tmp/template_check`: Presenza template
- `/tmp/homelab_deployed`: Stato deploy Ansible

### Controllo Template Avanzato
Per un controllo preciso dei template, il sistema può usare l'API di Proxmox:
```bash
# Se hai configurato token API in terraform.tfvars:
proxmox_token_id     = "root@pam!terraform"
proxmox_token_secret = "your-secret-token"

# Il sistema userà automaticamente l'API per verificare i template
make check-templates
```

**Nota**: I token sono già configurati nel tuo `terraform.tfvars` e verranno usati automaticamente!

## 🚨 Sicurezza

### Conferme Richieste
- **Deploy automatizzato**: Conferma prima dell'avvio
- **Reset completo**: Richiede digitare "RESET"
- **Modifiche Terraform**: Conferma automatica solo per creazione, richiede conferma per modifiche

### File Sensibili
- `secrets.yml`: Escluso da Git
- `terraform.tfvars`: Contiene credenziali Proxmox
- `credentials.pkr.hcl`: Credenziali Packer

## 📝 Esempi Pratici

### Setup Iniziale Completo
```bash
# 1. Verifica prerequisiti
make check

# 2. Deploy automatizzato completo
make deploy-complete

# 3. Verifica risultato
make status-all
```

### Aggiornamento Configurazione
```bash
# Modifica ansible/playbooks/templates/traefik.yml.j2
# o altri file di configurazione

# Deploy incrementale
make deploy-complete
# Il sistema rileverà le modifiche e chiederà conferma
```

### Troubleshooting
```bash
# Test connettività
make test-connectivity

# Verifica logs
make logs-services

# Se problemi gravi, reset completo
make reset-all
```

## 🎉 Vantaggi

✅ **Un comando solo**: `make deploy-complete` per tutto
✅ **Intelligente**: Rileva stato e applica solo il necessario  
✅ **Sicuro**: Conferme per operazioni distruttive
✅ **Robusto**: Gestione errori e timeout automatici
✅ **Trasparente**: Output colorato e dettagliato
✅ **Incremental**: Deploy solo delle modifiche necessarie

## 🔍 Troubleshooting Comune

### Template non trovato
```bash
make ensure-templates  # Forza creazione template
```

### VM non rispondono
```bash
make test-connectivity  # Verifica connettività
make terraform-status   # Controlla stato VM
```

### Servizi non attivi
```bash
make logs-services      # Verifica logs
make ansible-ping       # Test connettività Ansible
```

### Reset necessario
```bash
make reset-all          # Reset completo (ATTENZIONE!)
```
