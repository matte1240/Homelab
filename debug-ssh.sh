#!/bin/bash

# Debug script per problemi SSH Packer
echo "=== Packer SSH Debug Script ==="

# Verifica chiavi SSH
echo "1. Verifica delle chiavi SSH:"
if [ -f ~/.ssh/id_rsa ]; then
    echo "✓ Chiave privata trovata: ~/.ssh/id_rsa"
    echo "  Permessi: $(ls -l ~/.ssh/id_rsa | cut -d' ' -f1)"
else
    echo "✗ Chiave privata NON trovata: ~/.ssh/id_rsa"
fi

if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "✓ Chiave pubblica trovata: ~/.ssh/id_rsa.pub"
else
    echo "✗ Chiave pubblica NON trovata: ~/.ssh/id_rsa.pub"
fi

# Verifica corrispondenza chiavi
echo -e "\n2. Verifica corrispondenza chiavi:"
PRIVATE_KEY_PUB=$(ssh-keygen -y -f ~/.ssh/id_rsa 2>/dev/null)
AUTHORIZED_KEY=$(cat debian-server-trixie/http/authorized_keys 2>/dev/null)

if [ "$PRIVATE_KEY_PUB" = "$AUTHORIZED_KEY" ]; then
    echo "✓ Le chiavi corrispondono"
else
    echo "✗ Le chiavi NON corrispondono"
    echo "  Chiave privata genera: $PRIVATE_KEY_PUB"
    echo "  File authorized_keys:  $AUTHORIZED_KEY"
fi

# Verifica configurazione di rete
echo -e "\n3. Verifica configurazione di rete:"
IP_CONFIG=$(ip route get 1.1.1.1 | grep -oP 'src \K\S+')
echo "IP sorgente per connessioni esterne: $IP_CONFIG"

BIND_ADDRESS=$(grep "http_bind_address" debian-server-trixie/debian-server-trixie.pkr.hcl | grep -oP '"\K[^"]+')
echo "HTTP bind address configurato: $BIND_ADDRESS"

if [ "$IP_CONFIG" = "$BIND_ADDRESS" ]; then
    echo "✓ Gli indirizzi IP corrispondono"
else
    echo "✗ Gli indirizzi IP NON corrispondono - questo potrebbe causare problemi"
fi

# Verifica porta HTTP
echo -e "\n4. Verifica porta HTTP:"
HTTP_PORT=$(grep "http_port_min" debian-server-trixie/debian-server-trixie.pkr.hcl | grep -oP '\d+')
echo "Porta HTTP configurata: $HTTP_PORT"

if netstat -tuln | grep -q ":$HTTP_PORT "; then
    echo "⚠ Porta $HTTP_PORT già in uso"
else
    echo "✓ Porta $HTTP_PORT disponibile"
fi

# Suggerimenti
echo -e "\n=== Suggerimenti per risolvere problemi SSH ==="
echo "1. Verifica che l'IP bind_address sia corretto per la tua rete"
echo "2. Aumenta il timeout SSH se la rete è lenta"
echo "3. Controlla i log di Packer con PACKER_LOG=1"
echo "4. Testa la connessione SSH manuale alla VM durante il build"
echo "5. Verifica che il firewall non blocchi le connessioni"
