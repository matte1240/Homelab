# Setup Secrets per Homelab

## Prima del primo deploy

1. **Copia il file di esempio dei secrets:**
   ```bash
   cp secrets.yml.example secrets.yml
   ```

2. **Modifica `secrets.yml` con i tuoi valori reali:**
   ```bash
   nano secrets.yml
   ```

3. **Assicurati che `secrets.yml` sia nel .gitignore** (già configurato)

## Configurazione Cloudflare DNS API Token

1. Vai su https://dash.cloudflare.com/profile/api-tokens
2. Clicca "Create Token" -> "Custom Token"
3. Configura i permessi:
   - **Zone:Read** per tutte le zone
   - **DNS:Edit** per tutte le zone (o solo per il tuo dominio)
4. Copia il token e inseriscilo in `secrets.yml`

## Deploy

Una volta configurato il file secrets, puoi fare il deploy normalmente:

```bash
ansible-playbook site.yml
```

## Note di Sicurezza

- Il file `secrets.yml` **NON** è tracciato da Git
- Mantieni sempre un backup sicuro dei tuoi secrets
- Ruota periodicamente le credenziali, specialmente i token API
- Non condividere mai il file `secrets.yml` in repository pubblici
