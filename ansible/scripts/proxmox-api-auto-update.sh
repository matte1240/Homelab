#!/bin/bash
# Script per aggiornamenti automatici Proxmox VE via API
# Configurazione: /etc/cron.d/proxmox-auto-update

# Configurazione
HOMELAB_DIR="/home/matteo/Homelab"
ANSIBLE_DIR="$HOMELAB_DIR/ansible"
LOG_DIR="/var/log/proxmox-auto-update"
NOTIFICATION_EMAIL="admin@matteobaracetti.com"
DATE=$(date +%Y%m%d-%H%M%S)

# Crea directory log se non esiste
mkdir -p "$LOG_DIR"

# File di log per questa esecuzione
LOG_FILE="$LOG_DIR/auto-api-update-$DATE.log"

# Funzione per logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Funzione per invio notifiche
send_notification() {
    local subject="$1"
    local message="$2"
    
    # Invia email se configurato
    if command -v mail >/dev/null 2>&1 && [ ! -z "$NOTIFICATION_EMAIL" ]; then
        echo "$message" | mail -s "$subject" "$NOTIFICATION_EMAIL"
    fi
    
    # Log locale
    log "$subject: $message"
}

# Funzione per check API Proxmox
check_proxmox_api() {
    log "Controllo API Proxmox..."
    cd "$ANSIBLE_DIR" || return 1
    
    # Test connettività API usando playbook dedicato
    if ansible-playbook playbooks/proxmox-api-management.yml --tags=status >/dev/null 2>&1; then
        log "API Proxmox raggiungibile"
        return 0
    else
        log "ERRORE: API Proxmox non raggiungibile"
        return 1
    fi
}

# Funzione per ottenere numero aggiornamenti disponibili
get_available_updates() {
    log "Controllo aggiornamenti disponibili via API..."
    cd "$ANSIBLE_DIR" || return 1
    
    # Usa playbook per controllare aggiornamenti
    local updates_output
    updates_output=$(ansible-playbook playbooks/proxmox-api-management.yml --tags=status 2>/dev/null | grep "Available:" | grep -o '[0-9]*' | head -1)
    
    if [ -z "$updates_output" ]; then
        echo "0"
    else
        echo "$updates_output"
    fi
}

# Funzione principale
main() {
    log "=== Inizio aggiornamento automatico Proxmox via API ==="
    
    # Cambia directory
    cd "$HOMELAB_DIR" || {
        send_notification "ERRORE: Auto-update Proxmox API" "Impossibile accedere alla directory $HOMELAB_DIR"
        exit 1
    }
    
    # Controlla connettività API Proxmox
    if ! check_proxmox_api; then
        send_notification "ERRORE: Auto-update Proxmox API" "API Proxmox non raggiungibile"
        exit 1
    fi
    
    log "API Proxmox raggiungibile, procedo con l'aggiornamento..."
    
    # Determina tipo di aggiornamento in base al giorno
    DAY_OF_WEEK=$(date +%u)  # 1=Lunedì, 7=Domenica
    DAY_OF_MONTH=$(date +%d)
    
    if [ "$DAY_OF_MONTH" = "01" ]; then
        # Primo del mese: aggiornamento completo
        log "Aggiornamento completo mensile via API..."
        update_type="complete"
        
        # Esegui aggiornamento completo via API
        if cd "$ANSIBLE_DIR" && ansible-playbook playbooks/proxmox-api-update.yml >> "$LOG_FILE" 2>&1; then
            send_notification "SUCCESSO: Aggiornamento completo Proxmox API" "Aggiornamento mensile via API completato con successo"
        else
            send_notification "ERRORE: Aggiornamento completo Proxmox API" "Aggiornamento mensile via API fallito. Controlla i log: $LOG_FILE"
            exit 1
        fi
        
    elif [ "$DAY_OF_WEEK" = "1" ]; then
        # Lunedì: manutenzione settimanale
        log "Manutenzione settimanale via API..."
        update_type="maintenance"
        
        # Esegui manutenzione via API
        if cd "$ANSIBLE_DIR" && ansible-playbook playbooks/proxmox-api-maintenance.yml >> "$LOG_FILE" 2>&1; then
            send_notification "SUCCESSO: Manutenzione Proxmox API" "Manutenzione settimanale via API completata"
        else
            send_notification "ERRORE: Manutenzione Proxmox API" "Manutenzione via API fallita. Controlla i log: $LOG_FILE"
            exit 1
        fi
        
    else
        # Altri giorni: aggiornamento rapido se necessario
        log "Controllo aggiornamenti disponibili via API..."
        update_type="quick"
        
        # Controlla se ci sono aggiornamenti
        updates_available=$(get_available_updates)
        
        if [ -z "$updates_available" ] || [ "$updates_available" -le 0 ]; then
            log "Nessun aggiornamento disponibile"
            send_notification "INFO: Auto-update Proxmox API" "Nessun aggiornamento disponibile oggi"
        else
            log "Trovati $updates_available aggiornamenti, eseguo aggiornamento via API..."
            
            # Per aggiornamenti rapidi, usa l'aggiornamento completo ma senza riavvio forzato
            if cd "$ANSIBLE_DIR" && ansible-playbook playbooks/proxmox-api-update.yml -e "proxmox_reboot_after_update=false" >> "$LOG_FILE" 2>&1; then
                send_notification "SUCCESSO: Aggiornamento rapido Proxmox API" "Aggiornati $updates_available pacchetti via API"
            else
                send_notification "ERRORE: Aggiornamento rapido Proxmox API" "Aggiornamento rapido via API fallito. Controlla i log: $LOG_FILE"
                exit 1
            fi
        fi
    fi
    
    # Status finale via API
    log "Controllo status finale via API..."
    cd "$ANSIBLE_DIR" && ansible-playbook playbooks/proxmox-api-management.yml --tags=status >> "$LOG_FILE" 2>&1
    
    log "=== Aggiornamento automatico via API completato ==="
    
    # Pulizia log vecchi (mantieni ultimi 30 giorni)
    find "$LOG_DIR" -name "auto-api-update-*.log" -mtime +30 -delete
}

# Gestione errori
trap 'send_notification "ERRORE: Auto-update Proxmox API" "Script terminato inaspettatamente. Log: $LOG_FILE"' ERR

# Esecuzione
main "$@"