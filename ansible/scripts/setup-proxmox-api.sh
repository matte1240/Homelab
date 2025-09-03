#!/bin/bash
# Script per configurare token API Proxmox VE
# Questo script aiuta a creare e configurare i token API necessari

echo "🔧 Configurazione Token API Proxmox VE"
echo "======================================"
echo ""

# Configurazione
PROXMOX_HOST=${1:-"192.168.178.70"}
SECRETS_FILE="/home/matteo/Homelab/ansible/secrets.yml"

echo "📋 Questo script ti aiuterà a:"
echo "   1. Creare un token API su Proxmox"
echo "   2. Configurare le credenziali nel file secrets.yml"
echo "   3. Testare la connettività API"
echo ""

# Controllo connettività
echo "🌐 Test connettività Proxmox..."
if ping -c 1 "$PROXMOX_HOST" >/dev/null 2>&1; then
    echo "✅ Host Proxmox ($PROXMOX_HOST) raggiungibile"
else
    echo "❌ Host Proxmox ($PROXMOX_HOST) non raggiungibile"
    echo "   Verifica l'IP e la connettività di rete"
    exit 1
fi

# Test interfaccia web
echo "🌐 Test interfaccia web Proxmox..."
if curl -k -s "https://$PROXMOX_HOST:8006" >/dev/null 2>&1; then
    echo "✅ Interfaccia web Proxmox disponibile"
else
    echo "❌ Interfaccia web Proxmox non raggiungibile"
    echo "   Verifica che Proxmox sia avviato e funzionante"
    exit 1
fi

echo ""
echo "🔑 CREAZIONE TOKEN API"
echo "====================="
echo ""
echo "Per creare un token API, devi accedere all'interfaccia web di Proxmox:"
echo ""
echo "1. Apri il browser e vai su: https://$PROXMOX_HOST:8006"
echo "2. Accedi con le credenziali di root"
echo "3. Vai su: Datacenter -> Permissions -> API Tokens"
echo "4. Clicca su 'Add' per creare un nuovo token"
echo ""
echo "Configurazione consigliata:"
echo "   • User: root@pam"
echo "   • Token ID: automation"
echo "   • Comment: Ansible automation token"
echo "   • Privilege Separation: NO (deseleziona)"
echo ""
echo "5. Clicca 'Add' e COPIA il Token Secret mostrato"
echo "   ⚠️  Il secret viene mostrato SOLO UNA VOLTA!"
echo ""

# Chiedi conferma per procedere
read -p "Hai creato il token? (y/N): " token_created
if [ "$token_created" != "y" ] && [ "$token_created" != "Y" ]; then
    echo "❌ Operazione annullata. Crea prima il token API."
    exit 1
fi

echo ""
echo "📝 CONFIGURAZIONE CREDENZIALI"
echo "============================="
echo ""

# Richiedi le informazioni del token
echo "Inserisci le informazioni del token appena creato:"
echo ""

read -p "Token ID (es: root@pam!automation): " token_id
if [ -z "$token_id" ]; then
    echo "❌ Token ID richiesto"
    exit 1
fi

echo ""
read -s -p "Token Secret: " token_secret
echo ""
if [ -z "$token_secret" ]; then
    echo "❌ Token Secret richiesto"
    exit 1
fi

echo ""
read -p "Nome nodo Proxmox [pve]: " node_name
node_name=${node_name:-"pve"}

echo ""
read -p "Password utente root (per fallback): " root_password

# Backup del file secrets esistente
if [ -f "$SECRETS_FILE" ]; then
    cp "$SECRETS_FILE" "$SECRETS_FILE.backup.$(date +%Y%m%d-%H%M%S)"
    echo "✅ Backup del file secrets creato"
fi

# Aggiorna il file secrets
echo ""
echo "📝 Aggiornamento file secrets.yml..."

# Rimuovi le linee esistenti relative all'API Proxmox
sed -i '/^# Proxmox API credentials/,/^vault_proxmox_node:/d' "$SECRETS_FILE" 2>/dev/null || true
sed -i '/^vault_proxmox_api_/d' "$SECRETS_FILE" 2>/dev/null || true

# Aggiungi le nuove configurazioni
cat >> "$SECRETS_FILE" << EOF

# Proxmox API credentials
vault_proxmox_api_url: "https://$PROXMOX_HOST:8006/api2/json"
vault_proxmox_api_user: "root@pam"
vault_proxmox_api_password: "$root_password"
vault_proxmox_api_token_id: "$token_id"
vault_proxmox_api_token_secret: "$token_secret"
vault_proxmox_node: "$node_name"
EOF

echo "✅ File secrets.yml aggiornato"

# Test della configurazione
echo ""
echo "🧪 TEST CONFIGURAZIONE API"
echo "========================="
echo ""

# Installa dipendenze Python se necessarie
echo "📦 Verifica dipendenze Python..."
if ! python3 -c "import requests" 2>/dev/null; then
    echo "📦 Installazione requests..."
    pip3 install requests
fi

# Test API con Python
echo "🔍 Test connettività API..."

python3 << EOF
import requests
import json
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# Configurazione
api_url = "https://$PROXMOX_HOST:8006/api2/json"
token_id = "$token_id"
token_secret = "$token_secret"

# Headers per autenticazione
headers = {
    "Authorization": f"PVEAPIToken={token_id}={token_secret}"
}

try:
    # Test connessione con versione
    response = requests.get(f"{api_url}/version", headers=headers, verify=False, timeout=10)
    
    if response.status_code == 200:
        data = response.json()
        print("✅ Connessione API riuscita!")
        print(f"   Versione Proxmox: {data['data']['version']}")
        
        # Test accesso nodo
        node_response = requests.get(f"{api_url}/nodes/$node_name/status", headers=headers, verify=False, timeout=10)
        if node_response.status_code == 200:
            node_data = node_response.json()
            print(f"✅ Accesso al nodo '$node_name' riuscito!")
            print(f"   PVE Version: {node_data['data']['pveversion']}")
            print(f"   Uptime: {node_data['data']['uptime']} secondi")
        else:
            print(f"⚠️  Problema accesso nodo: {node_response.status_code}")
            
    else:
        print(f"❌ Connessione API fallita: {response.status_code}")
        print(f"   Errore: {response.text}")
        
except Exception as e:
    print(f"❌ Errore di connessione: {str(e)}")
EOF

echo ""
echo "🎯 CONFIGURAZIONE COMPLETATA"
echo "============================"
echo ""
echo "📁 File aggiornati:"
echo "   • $SECRETS_FILE"
echo "   • Backup: $SECRETS_FILE.backup.*"
echo ""
echo "🚀 Comandi disponibili:"
echo "   make proxmox-api-status    # Test API e status"
echo "   make proxmox-api-update    # Aggiornamento via API"
echo "   make proxmox-api-maintenance # Manutenzione via API"
echo ""
echo "🔗 Collegamenti utili:"
echo "   • Proxmox Web: https://$PROXMOX_HOST:8006"
echo "   • API Docs: https://$PROXMOX_HOST:8006/pve-docs/api-viewer/"
echo ""

# Test con ansible se disponibile
if command -v ansible-playbook >/dev/null 2>&1; then
    echo "🧪 Test con Ansible..."
    cd /home/matteo/Homelab/ansible
    if ansible-playbook playbooks/proxmox-api-management.yml --tags=status 2>/dev/null | grep -q "PROXMOX VE API STATUS"; then
        echo "✅ Test Ansible riuscito!"
    else
        echo "⚠️  Test Ansible non completamente riuscito - verifica la configurazione"
    fi
fi

echo ""
echo "✅ Setup completato! Ora puoi utilizzare le API di Proxmox."