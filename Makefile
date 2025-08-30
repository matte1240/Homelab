# Makefile per la gestione dell'homelab Proxmox
# Uso: make <target> per eseguire le operazioni

# Variabili di configurazione
PACKER := packer
TERRAFORM := terraform
ANSIBLE := ansible
ANSIBLE_PLAYBOOK := ansible-playbook
PACKER_DIR := packer
TERRAFORM_DIR := terraform
ANSIBLE_DIR := ansible
CREDENTIALS := $(PACKER_DIR)/credentials.pkr.hcl
PACKER_LOG_LEVEL := 1

# Colori per output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Template disponibili
UBUNTU_TEMPLATE := $(PACKER_DIR)/ubuntu-server-noble
DEBIAN_TRIXIE_TEMPLATE := $(PACKER_DIR)/debian-server-trixie

# Target predefinito
.DEFAULT_GOAL := help

# Aiuto
.PHONY: help
help:
	@echo "$(BLUE)=== Makefile Homelab Proxmox ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Target principali:$(NC)"
	@echo "  $(GREEN)help$(NC)                    - Mostra questo aiuto"
	@echo "  $(GREEN)check$(NC)                   - Verifica prerequisiti e configurazione"
	@echo "  $(GREEN)clean$(NC)                   - Pulisce file temporanei e cache"
	@echo "  $(GREEN)clean-all$(NC)               - Pulizia completa (include terraform)"
	@echo ""
	@echo "$(YELLOW)Packer Templates:$(NC)"
	@echo "  $(GREEN)validate-all$(NC)            - Valida tutti i template"
	@echo "  $(GREEN)build-all$(NC)               - Costruisce tutti i template"
	@echo "  $(GREEN)validate-ubuntu$(NC)         - Valida template Ubuntu Noble"
	@echo "  $(GREEN)build-ubuntu$(NC)            - Costruisce template Ubuntu Noble"
	@echo "  $(GREEN)validate-debian-trixie$(NC)  - Valida template Debian Trixie"
	@echo "  $(GREEN)build-debian-trixie$(NC)     - Costruisce template Debian Trixie"
	@echo ""
	@echo "$(YELLOW)Terraform Infrastructure:$(NC)"
	@echo "  $(GREEN)terraform-init$(NC)          - Inizializza Terraform"
	@echo "  $(GREEN)terraform-plan$(NC)          - Mostra plan Terraform"
	@echo "  $(GREEN)terraform-apply$(NC)         - Applica configurazione"
	@echo "  $(GREEN)terraform-destroy$(NC)       - Distrugge infrastruttura"
	@echo "  $(GREEN)terraform-status$(NC)        - Mostra stato infrastruttura"
	@echo "  $(GREEN)terraform-validate$(NC)      - Valida configurazione Terraform"
	@echo "  $(GREEN)terraform-fmt$(NC)           - Formatta file Terraform"
	@echo "  $(GREEN)clean-terraform$(NC)         - Pulisce solo file Terraform"
	@echo ""
	@echo "$(YELLOW)Ansible Configuration:$(NC)"
	@echo "  $(GREEN)ansible-check$(NC)           - Verifica configurazione Ansible"
	@echo "  $(GREEN)ansible-ping$(NC)            - Testa connettività agli host"
	@echo "  $(GREEN)ansible-deploy$(NC)          - Esegue playbook principale"
	@echo "  $(GREEN)ansible-deploy-staging$(NC)  - Deploy su ambiente staging"
	@echo "  $(GREEN)ansible-docker-compose$(NC)  - Installa Docker Compose su Ubuntu VM"
	@echo "  $(GREEN)ansible-pihole$(NC)          - Deploy Pi-hole + Unbound DNS stack"
	@echo "  $(GREEN)ansible-lint$(NC)            - Analizza playbook con ansible-lint"
	@echo "  $(GREEN)ansible-vault-edit$(NC)      - Modifica vault per secrets"
	@echo ""
	@echo "$(YELLOW)Utilità:$(NC)"
	@echo "  $(GREEN)show-ips$(NC)                - Mostra configurazione IP"
	@echo "  $(GREEN)dev-check$(NC)               - Controlli di sviluppo"
	@echo ""
	@echo "$(YELLOW)Esempi:$(NC)"
	@echo "  make check                    # Verifica prerequisiti"
	@echo "  make build-ubuntu             # Costruisce solo Ubuntu"
	@echo "  make terraform-plan           # Mostra piano terraform"
	@echo "  PACKER_LOG=1 make build-all  # Build con log dettagliati"

# Verifica prerequisiti
.PHONY: check
check:
	@echo "$(BLUE)=== Verifica Prerequisiti ===$(NC)"
	@echo -n "$(YELLOW)Checking Packer...$(NC) "
	@if command -v $(PACKER) >/dev/null 2>&1; then \
		echo "$(GREEN)✓ $(shell $(PACKER) version)$(NC)"; \
	else \
		echo "$(RED)✗ Packer non trovato$(NC)"; exit 1; \
	fi
	@echo -n "$(YELLOW)Checking Terraform...$(NC) "
	@if command -v $(TERRAFORM) >/dev/null 2>&1; then \
		echo "$(GREEN)✓ $(shell $(TERRAFORM) version | head -n1)$(NC)"; \
	else \
		echo "$(RED)✗ Terraform non trovato$(NC)"; exit 1; \
	fi
	@echo -n "$(YELLOW)Checking Ansible...$(NC) "
	@if command -v $(ANSIBLE) >/dev/null 2>&1; then \
		echo "$(GREEN)✓ $(shell $(ANSIBLE) --version | head -n1)$(NC)"; \
	else \
		echo "$(RED)✗ Ansible non trovato$(NC)"; exit 1; \
	fi
	@echo -n "$(YELLOW)Checking credentials...$(NC) "
	@if [ -f "$(CREDENTIALS)" ]; then \
		echo "$(GREEN)✓ File credenziali trovato$(NC)"; \
	else \
		echo "$(RED)✗ File $(CREDENTIALS) non trovato$(NC)"; \
		echo "$(YELLOW)Esegui: cp $(PACKER_DIR)/credentials.pkr.hcl.example $(CREDENTIALS)$(NC)"; \
		exit 1; \
	fi
	@echo -n "$(YELLOW)Checking SSH keys...$(NC) "
	@if [ -f "$$HOME/.ssh/id_rsa" ]; then \
		echo "$(GREEN)✓ Chiave SSH trovata$(NC)"; \
	else \
		echo "$(RED)✗ Chiave SSH non trovata$(NC)"; \
		echo "$(YELLOW)Esegui: ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa$(NC)"; \
		exit 1; \
	fi

# Mostra configurazione IP
.PHONY: show-ips
show-ips:
	@echo "$(BLUE)=== Configurazione IP ===$(NC)"
	@echo "$(YELLOW)IP di sistema:$(NC) $(shell ip route get 1.1.1.1 | grep -oP 'src \K\S+')"
	@echo "$(YELLOW)Ubuntu template:$(NC) $(shell grep http_bind_address $(UBUNTU_TEMPLATE)/ubuntu-server-noble.pkr.hcl | grep -oP '"\K[^"]+')"
	@if [ -f "$(DEBIAN_TRIXIE_TEMPLATE)/debian-server-trixie.pkr.hcl" ]; then \
		echo "$(YELLOW)Debian Trixie:$(NC) $(shell grep http_bind_address $(DEBIAN_TRIXIE_TEMPLATE)/debian-server-trixie.pkr.hcl | grep -oP '"\K[^"]+')"; \
	fi

# Validazione template
.PHONY: validate-ubuntu
validate-ubuntu:
	@echo "$(BLUE)=== Validazione Template Ubuntu ===$(NC)"
	cd $(UBUNTU_TEMPLATE) && $(PACKER) validate -var-file="../credentials.pkr.hcl" ubuntu-server-noble.pkr.hcl

.PHONY: validate-debian-trixie
validate-debian-trixie:
	@echo "$(BLUE)=== Validazione Template Debian Trixie ===$(NC)"
	cd $(DEBIAN_TRIXIE_TEMPLATE) && $(PACKER) validate -var-file="../credentials.pkr.hcl" debian-server-trixie.pkr.hcl

.PHONY: validate-all
validate-all: validate-ubuntu validate-debian-trixie
	@echo "$(GREEN)=== Tutti i template validati con successo ===$(NC)"

# Build template
.PHONY: build-ubuntu
build-ubuntu: validate-ubuntu
	@echo "$(BLUE)=== Build Template Ubuntu Noble ===$(NC)"
	cd $(UBUNTU_TEMPLATE) && PACKER_LOG=$(PACKER_LOG_LEVEL) $(PACKER) build -var-file="../credentials.pkr.hcl" ubuntu-server-noble.pkr.hcl

.PHONY: build-debian-trixie
build-debian-trixie: validate-debian-trixie
	@echo "$(BLUE)=== Build Template Debian Trixie ===$(NC)"
	cd $(DEBIAN_TRIXIE_TEMPLATE) && PACKER_LOG=$(PACKER_LOG_LEVEL) $(PACKER) build -var-file="../credentials.pkr.hcl" debian-server-trixie.pkr.hcl

.PHONY: build-all
build-all: check
	@echo "$(BLUE)=== Build di tutti i template ===$(NC)"
	@echo "$(YELLOW)Attenzione: Questo processo può richiedere molto tempo!$(NC)"
	@echo "$(YELLOW)I template verranno costruiti in sequenza per evitare conflitti di risorse.$(NC)"
	@echo ""
	@$(MAKE) build-ubuntu
	@echo ""
	@$(MAKE) build-debian-trixie
	@echo ""
	@echo "$(GREEN)=== Tutti i template completati con successo! ===$(NC)"

# ================================================
# TERRAFORM TARGETS
# ================================================

# Inizializzazione Terraform
.PHONY: terraform-init
terraform-init:
	@echo "$(BLUE)=== Inizializzazione Terraform ===$(NC)"
	cd $(TERRAFORM_DIR) && $(TERRAFORM) init

# Plan Terraform
.PHONY: terraform-plan
terraform-plan:
	@echo "$(BLUE)=== Terraform Plan ===$(NC)"
	cd $(TERRAFORM_DIR) && $(TERRAFORM) plan

# Apply Terraform
.PHONY: terraform-apply
terraform-apply:
	@echo "$(BLUE)=== Terraform Apply ===$(NC)"
	@echo "$(YELLOW)Attenzione: Questa operazione modificherà l'infrastruttura!$(NC)"
	@read -p "Confermi l'applicazione? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd $(TERRAFORM_DIR) && $(TERRAFORM) apply; \
	else \
		echo "$(YELLOW)Operazione annullata$(NC)"; \
	fi

# Destroy Terraform
.PHONY: terraform-destroy
terraform-destroy:
	@echo "$(BLUE)=== Terraform Destroy ===$(NC)"
	@echo "$(RED)ATTENZIONE: Questa operazione distruggerà l'intera infrastruttura!$(NC)"
	@read -p "Sei SICURO di voler continuare? (type 'yes' to confirm): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		cd $(TERRAFORM_DIR) && $(TERRAFORM) destroy; \
	else \
		echo "$(YELLOW)Operazione annullata$(NC)"; \
	fi

# Status Terraform
.PHONY: terraform-status
terraform-status:
	@echo "$(BLUE)=== Stato Terraform ===$(NC)"
	@echo "$(YELLOW)Workspace corrente:$(NC)"
	@cd $(TERRAFORM_DIR) && $(TERRAFORM) workspace show 2>/dev/null || echo "default"
	@echo ""
	@echo "$(YELLOW)Stato delle risorse:$(NC)"
	@cd $(TERRAFORM_DIR) && $(TERRAFORM) state list 2>/dev/null || echo "Nessuna risorsa trovata o terraform non inizializzato"

# Validazione Terraform
.PHONY: terraform-validate
terraform-validate:
	@echo "$(BLUE)=== Validazione Terraform ===$(NC)"
	cd $(TERRAFORM_DIR) && $(TERRAFORM) validate

# Format Terraform
.PHONY: terraform-fmt
terraform-fmt:
	@echo "$(BLUE)=== Format Terraform ===$(NC)"
	cd $(TERRAFORM_DIR) && $(TERRAFORM) fmt -recursive

# ================================================
# PULIZIA
# ================================================

# Pulizia standard (file temporanei e cache)
.PHONY: clean
clean:
	@echo "$(BLUE)=== Pulizia file temporanei ===$(NC)"
	@find . -name "*.log" -type f -delete 2>/dev/null || true
	@find . -name "packer_cache" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".packer" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)Pulizia standard completata$(NC)"

# Pulizia completa (include file terraform e cache)
.PHONY: clean-all
clean-all: clean
	@echo "$(BLUE)=== Pulizia completa ===$(NC)"
	@echo "$(YELLOW)Rimuovo file terraform temporanei...$(NC)"
	@find $(TERRAFORM_DIR) -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find $(TERRAFORM_DIR) -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true
	@find $(TERRAFORM_DIR) -name "*.tfplan" -type f -delete 2>/dev/null || true
	@find $(TERRAFORM_DIR) -name "crash.log" -type f -delete 2>/dev/null || true
	@echo "$(GREEN)Pulizia completa terminata$(NC)"

# Pulizia terraform (solo terraform, utile per re-init)
.PHONY: clean-terraform
clean-terraform:
	@echo "$(BLUE)=== Pulizia Terraform ===$(NC)"
	@echo "$(YELLOW)Attenzione: Questo rimuoverà .terraform/ e richiederà re-init$(NC)"
	@read -p "Confermi la pulizia terraform? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -rf $(TERRAFORM_DIR)/.terraform 2>/dev/null || true; \
		rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl 2>/dev/null || true; \
		echo "$(GREEN)Pulizia terraform completata$(NC)"; \
	else \
		echo "$(YELLOW)Operazione annullata$(NC)"; \
	fi

# Build veloce (solo validazione + build senza check completo)
.PHONY: quick-ubuntu quick-debian-trixie
quick-ubuntu:
	@$(MAKE) build-ubuntu PACKER_LOG_LEVEL=0

quick-debian-trixie:
	@$(MAKE) build-debian-trixie PACKER_LOG_LEVEL=0

# Target per sviluppatori
.PHONY: dev-check
dev-check:
	@echo "$(BLUE)=== Controlli di sviluppo ===$(NC)"
	@echo "$(YELLOW)Verifico struttura progetto...$(NC)"
	@for template in $(UBUNTU_TEMPLATE) $(DEBIAN_TRIXIE_TEMPLATE); do \
		if [ -d "$$template" ]; then \
			echo "$(GREEN)✓$(NC) Directory $$template esistente"; \
			if [ -f "$$template/$$template.pkr.hcl" ]; then \
				echo "$(GREEN)  ✓$(NC) File $$template.pkr.hcl trovato"; \
			else \
				echo "$(RED)  ✗$(NC) File $$template.pkr.hcl mancante"; \
			fi; \
			if [ -d "$$template/http" ]; then \
				echo "$(GREEN)  ✓$(NC) Directory http trovata"; \
			else \
				echo "$(RED)  ✗$(NC) Directory http mancante"; \
			fi; \
			if [ -d "$$template/files" ]; then \
				echo "$(GREEN)  ✓$(NC) Directory files trovata"; \
			else \
				echo "$(RED)  ✗$(NC) Directory files mancante"; \
			fi; \
		else \
			echo "$(RED)✗$(NC) Directory $$template mancante"; \
		fi; \
	done

# ================================================
# ANSIBLE TARGETS
# ================================================

# Verifica configurazione Ansible
.PHONY: ansible-check
ansible-check:
	@echo "$(BLUE)=== Verifica Configurazione Ansible ===$(NC)"
	@echo -n "$(YELLOW)Checking Ansible config...$(NC) "
	@if [ -f "$(ANSIBLE_DIR)/ansible.cfg" ]; then \
		echo "$(GREEN)✓ File ansible.cfg trovato$(NC)"; \
	else \
		echo "$(RED)✗ File ansible.cfg mancante$(NC)"; exit 1; \
	fi
	@echo -n "$(YELLOW)Checking inventory...$(NC) "
	@if [ -f "$(ANSIBLE_DIR)/inventories/production/hosts.yml" ]; then \
		echo "$(GREEN)✓ Inventory production trovato$(NC)"; \
	else \
		echo "$(RED)✗ Inventory production mancante$(NC)"; exit 1; \
	fi
	@echo "$(GREEN)Configurazione Ansible verificata$(NC)"

# Test connettività
.PHONY: ansible-ping
ansible-ping:
	@echo "$(BLUE)=== Test Connettività Ansible ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE) all -m ping

.PHONY: ansible-ping-staging
ansible-ping-staging:
	@echo "$(BLUE)=== Test Connettività Staging ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE) -i inventories/staging/hosts.yml all -m ping

# Deploy playbook principale
.PHONY: ansible-deploy
ansible-deploy: ansible-check
	@echo "$(BLUE)=== Deploy Ansible Production ===$(NC)"
	@echo "$(YELLOW)Attenzione: Questa operazione configurerà i server in produzione!$(NC)"
	@read -p "Confermi il deploy? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/site.yml; \
	else \
		echo "$(YELLOW)Operazione annullata$(NC)"; \
	fi

# Deploy ambiente staging
.PHONY: ansible-deploy-staging
ansible-deploy-staging:
	@echo "$(BLUE)=== Deploy Ansible Staging ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventories/staging/hosts.yml playbooks/site.yml

# Lint playbooks
.PHONY: ansible-lint
ansible-lint:
	@echo "$(BLUE)=== Ansible Lint ===$(NC)"
	@if command -v ansible-lint >/dev/null 2>&1; then \
		cd $(ANSIBLE_DIR) && ansible-lint playbooks/; \
	else \
		echo "$(YELLOW)ansible-lint non trovato, installa con: pip install ansible-lint$(NC)"; \
	fi

# Gestione vault
.PHONY: ansible-vault-edit
ansible-vault-edit:
	@echo "$(BLUE)=== Modifica Ansible Vault ===$(NC)"
	@if [ ! -f "$(ANSIBLE_DIR)/group_vars/vault.yml" ]; then \
		echo "$(YELLOW)Creazione nuovo file vault...$(NC)"; \
		cd $(ANSIBLE_DIR) && ansible-vault create group_vars/vault.yml; \
	else \
		cd $(ANSIBLE_DIR) && ansible-vault edit group_vars/vault.yml; \
	fi

# Deploy Docker Compose
.PHONY: ansible-docker-compose
ansible-docker-compose: ansible-check
	@echo "$(BLUE)=== Deploy Docker Compose ===$(NC)"
	@echo "$(YELLOW)Installazione Docker Compose su Ubuntu VM...$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/docker-compose.yml

# Deploy Pi-hole + Unbound
.PHONY: ansible-pihole
ansible-pihole: ansible-check
	@echo "$(BLUE)=== Deploy Pi-hole + Unbound DNS Stack ===$(NC)"
	@echo "$(YELLOW)Configurazione systemd-resolved e deploy Pi-hole + Unbound...$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/pihole-unbound.yml
