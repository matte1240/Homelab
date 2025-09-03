#!/bin/bash
# Script per aggiornamenti automatici Proxmox VE
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
LOG_FILE="$LOG_DIR/auto-update-$DATE.log"

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

# Funzione principale
main() {
    log "=== Inizio aggiornamento automatico Proxmox ==="
    
    # Cambia directory
    cd "$HOMELAB_DIR" || {
        send_notification "ERRORE: Auto-update Proxmox" "Impossibile accedere alla directory $HOMELAB_DIR"
        exit 1
    }
    
    # Controlla connettività Proxmox
    log "Controllo connettività Proxmox..."
    if ! make proxmox-ping >/dev/null 2>&1; then
        send_notification "ERRORE: Auto-update Proxmox" "Server Proxmox non raggiungibile"
        exit 1
    fi
    
    log "Server Proxmox raggiungibile, procedo con l'aggiornamento..."
    
    # Determina tipo di aggiornamento in base al giorno
    DAY_OF_WEEK=$(date +%u)  # 1=Lunedì, 7=Domenica
    DAY_OF_MONTH=$(date +%d)
    
    if [ "$DAY_OF_MONTH" = "01" ]; then
        # Primo del mese: aggiornamento completo
        log "Aggiornamento completo mensile..."
        update_type="complete"
        
        # Esegui aggiornamento completo
        if make proxmox-update >> "$LOG_FILE" 2>&1; then
            send_notification "SUCCESSO: Aggiornamento completo Proxmox" "Aggiornamento mensile completato con successo"
        else
            send_notification "ERRORE: Aggiornamento completo Proxmox" "Aggiornamento mensile fallito. Controlla i log: $LOG_FILE"
            exit 1
        fi
        
    elif [ "$DAY_OF_WEEK" = "1" ]; then
        # Lunedì: manutenzione settimanale
        log "Manutenzione settimanale..."
        update_type="maintenance"
        
        # Esegui manutenzione
        if make proxmox-maintenance >> "$LOG_FILE" 2>&1; then
            send_notification "SUCCESSO: Manutenzione Proxmox" "Manutenzione settimanale completata"
        else
            send_notification "ERRORE: Manutenzione Proxmox" "Manutenzione fallita. Controlla i log: $LOG_FILE"
            exit 1
        fi
        
    else
        # Altri giorni: aggiornamento rapido se necessario
        log "Controllo aggiornamenti disponibili..."
        update_type="quick"
        
        # Controlla se ci sono aggiornamenti
        updates_available=$(cd "$ANSIBLE_DIR" && ansible -i inventories/proxmox proxmox -m shell -a "apt list --upgradable 2>/dev/null | grep -v WARNING | wc -l" 2>/dev/null | grep -o '[0-9]*' | head -1)
        
        if [ -z "$updates_available" ] || [ "$updates_available" -le 1 ]; then
            log "Nessun aggiornamento disponibile"
            send_notification "INFO: Auto-update Proxmox" "Nessun aggiornamento disponibile oggi"
        else
            log "Trovati $updates_available aggiornamenti, eseguo aggiornamento rapido..."
            
            if make proxmox-quick-update >> "$LOG_FILE" 2>&1; then
                send_notification "SUCCESSO: Aggiornamento rapido Proxmox" "Aggiornati $updates_available pacchetti"
            else
                send_notification "ERRORE: Aggiornamento rapido Proxmox" "Aggiornamento rapido fallito. Controlla i log: $LOG_FILE"
                exit 1
            fi
        fi
    fi
    
    # Status finale
    log "Controllo status finale..."
    make proxmox-status >> "$LOG_FILE" 2>&1
    
    log "=== Aggiornamento automatico completato ==="
    
    # Pulizia log vecchi (mantieni ultimi 30 giorni)
    find "$LOG_DIR" -name "auto-update-*.log" -mtime +30 -delete
}

# Gestione errori
trap 'send_notification "ERRORE: Auto-update Proxmox" "Script terminato inaspettatamente. Log: $LOG_FILE"' ERR

# Esecuzione
main "$@"