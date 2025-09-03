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
DEBIAN_TEMPLATE := $(PACKER_DIR)/debian-server-trixie

# Target predefinito
.DEFAULT_GOAL := help

# Aiuto
.PHONY: help
help:
	@echo "$(BLUE)=== Homelab Makefile ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Main Commands:$(NC)"
	@echo "  $(GREEN)deploy-complete$(NC)  - Full automated deployment (recommended)"
	@echo "  $(GREEN)check$(NC)            - Verify prerequisites"
	@echo "  $(GREEN)status-all$(NC)       - Show complete homelab status"
	@echo "  $(GREEN)clean$(NC)            - Clean temporary files"
	@echo ""
	@echo "$(YELLOW)Build & Deploy:$(NC)"
	@echo "  $(GREEN)build-all$(NC)        - Build all Packer templates"
	@echo "  $(GREEN)terraform-apply$(NC)  - Apply Terraform configuration"
	@echo "  $(GREEN)deploy-production$(NC) - Deploy to production environment"
	@echo "  $(GREEN)deploy-development$(NC) - Deploy to development environment"
	@echo ""
	@echo "$(YELLOW)Proxmox Management:$(NC)"
	@echo "  $(GREEN)proxmox-menu$(NC)      - Show Proxmox management options"
	@echo "  $(GREEN)proxmox-api-setup$(NC) - Setup Proxmox API access"
	@echo "  $(GREEN)proxmox-api-status$(NC) - Check Proxmox status via API"
	@echo "  $(GREEN)proxmox-api-update$(NC) - Update Proxmox via API"
	@echo "  $(GREEN)proxmox-status$(NC)    - Check Proxmox status via SSH"
	@echo "  $(GREEN)proxmox-update$(NC)    - Update Proxmox via SSH"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make deploy-complete    # Complete automated deployment"
	@echo "  make check              # Verify setup"
	@echo "  make status-all         # Check all services"
	@echo "  make proxmox-menu       # Proxmox management menu"

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
# DEPLOY AUTOMATIZZATO COMPLETO
# ================================================

# Verifica template Packer esistenti su Proxmox
.PHONY: check-templates
check-templates:
	@echo "$(BLUE)=== Controllo Template su Proxmox ===$(NC)"
	@echo "$(YELLOW)Verifico presenza template necessari...$(NC)"
	@UBUNTU_TEMPLATE_ID=$$(grep 'ubuntu_template_id' $(TERRAFORM_DIR)/terraform.tfvars | grep -oE '[0-9]+' || echo "900"); \
	PROXMOX_HOST=$$(grep 'proxmox_api_url' $(TERRAFORM_DIR)/terraform.tfvars | sed 's/.*https:\/\/\([^:]*\).*/\1/' || echo "192.168.178.70"); \
	PROXMOX_TOKEN_ID=$$(grep 'proxmox_token_id' $(TERRAFORM_DIR)/terraform.tfvars | sed 's/.*= *"\([^"]*\)".*/\1/' || echo ""); \
	PROXMOX_TOKEN_SECRET=$$(grep 'proxmox_token_secret' $(TERRAFORM_DIR)/terraform.tfvars | sed 's/.*= *"\([^"]*\)".*/\1/' || echo ""); \
	echo "$(YELLOW)Controllo template Ubuntu (ID: $$UBUNTU_TEMPLATE_ID) su $$PROXMOX_HOST...$(NC)"; \
	if command -v pvesh >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Usando pvesh per controllo diretto$(NC)"; \
		if pvesh get /nodes/pve/qemu/$$UBUNTU_TEMPLATE_ID/config >/dev/null 2>&1; then \
			echo "$(GREEN)✓ Template Ubuntu ($$UBUNTU_TEMPLATE_ID) trovato$(NC)"; \
			echo "ubuntu_template_exists=true" > /tmp/template_check; \
		else \
			echo "$(RED)✗ Template Ubuntu ($$UBUNTU_TEMPLATE_ID) non trovato$(NC)"; \
			echo "ubuntu_template_exists=false" > /tmp/template_check; \
		fi; \
	elif [ ! -z "$$PROXMOX_TOKEN_ID" ] && [ ! -z "$$PROXMOX_TOKEN_SECRET" ]; then \
		echo "$(GREEN)✓ Usando API REST per controllo template$(NC)"; \
		HTTP_CODE=$$(curl -k -s -o /dev/null -w "%{http_code}" \
			-H "Authorization: PVEAPIToken=$$PROXMOX_TOKEN_ID=$$PROXMOX_TOKEN_SECRET" \
			"https://$$PROXMOX_HOST:8006/api2/json/nodes/pve/qemu/$$UBUNTU_TEMPLATE_ID/config" 2>/dev/null || echo "000"); \
		if [ "$$HTTP_CODE" = "200" ]; then \
			echo "$(GREEN)✓ Template Ubuntu ($$UBUNTU_TEMPLATE_ID) trovato via API$(NC)"; \
			echo "ubuntu_template_exists=true" > /tmp/template_check; \
		else \
			echo "$(RED)✗ Template Ubuntu ($$UBUNTU_TEMPLATE_ID) non trovato (HTTP: $$HTTP_CODE)$(NC)"; \
			echo "ubuntu_template_exists=false" > /tmp/template_check; \
		fi; \
	else \
		echo "$(YELLOW)⚠ pvesh e credenziali API non disponibili, uso controllo di base...$(NC)"; \
		if ping -c 1 $$PROXMOX_HOST >/dev/null 2>&1; then \
			echo "$(YELLOW)Host Proxmox raggiungibile, assumo template presente$(NC)"; \
			echo "ubuntu_template_exists=true" > /tmp/template_check; \
		else \
			echo "$(RED)✗ Host Proxmox non raggiungibile$(NC)"; \
			echo "ubuntu_template_exists=false" > /tmp/template_check; \
		fi; \
	fi

# Garantisce presenza template necessari
.PHONY: ensure-templates
ensure-templates: check-templates
	@echo "$(BLUE)=== Verifica e Creazione Template ===$(NC)"
	@if [ -f /tmp/template_check ]; then \
		source /tmp/template_check 2>/dev/null || ubuntu_template_exists=false; \
		if [ "$$ubuntu_template_exists" = "false" ]; then \
			echo "$(YELLOW)Template Ubuntu mancante, procedo con la creazione...$(NC)"; \
			$(MAKE) build-ubuntu; \
			echo "$(GREEN)✓ Template Ubuntu creato con successo$(NC)"; \
		else \
			echo "$(GREEN)✓ Template Ubuntu già presente$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)Stato template non determinato, creo template per sicurezza...$(NC)"; \
		$(MAKE) build-ubuntu; \
	fi
	@rm -f /tmp/template_check

# Verifica e gestione stato Terraform
.PHONY: terraform-check-and-apply
terraform-check-and-apply:
	@echo "$(BLUE)=== Verifica e Gestione Terraform ===$(NC)"
	@cd $(TERRAFORM_DIR) && \
	if [ ! -d ".terraform" ]; then \
		echo "$(YELLOW)Terraform non inizializzato, procedo con init...$(NC)"; \
		$(TERRAFORM) init; \
	fi; \
	echo "$(YELLOW)Controllo stato delle VM...$(NC)"; \
	CURRENT_STATE=$$($(TERRAFORM) state list | wc -l); \
	if [ $$CURRENT_STATE -eq 0 ]; then \
		echo "$(YELLOW)Nessuna VM presente, procedo con la creazione...$(NC)"; \
		$(TERRAFORM) apply -auto-approve; \
		echo "$(GREEN)✓ VM create con successo$(NC)"; \
	else \
		echo "$(YELLOW)VM esistenti rilevate, controllo se sono aggiornate...$(NC)"; \
		$(TERRAFORM) plan -detailed-exitcode -out=tf.plan; \
		PLAN_EXIT_CODE=$$?; \
		if [ $$PLAN_EXIT_CODE -eq 2 ]; then \
			echo "$(YELLOW)Modifiche rilevate, applico aggiornamenti...$(NC)"; \
			$(TERRAFORM) apply tf.plan; \
			echo "$(GREEN)✓ VM aggiornate con successo$(NC)"; \
		elif [ $$PLAN_EXIT_CODE -eq 1 ]; then \
			echo "$(RED)✗ Errore nel plan Terraform$(NC)"; \
			exit 1; \
		else \
			echo "$(GREEN)✓ VM già aggiornate$(NC)"; \
		fi; \
		rm -f tf.plan; \
	fi

# Deploy Ansible completo o incrementale
.PHONY: ansible-deploy-smart
ansible-deploy-smart:
	@echo "$(BLUE)=== Deploy Ansible Intelligente ===$(NC)"
	@echo "$(YELLOW)Verifico stato deploy precedenti...$(NC)"
	@cd $(ANSIBLE_DIR) && \
	if $(ANSIBLE) all -m ping --one-line 2>/dev/null | grep -q "SUCCESS"; then \
		echo "$(GREEN)✓ Host raggiungibili$(NC)"; \
		echo "$(YELLOW)Controllo se è necessario un deploy completo...$(NC)"; \
		if [ ! -f /tmp/homelab_deployed ]; then \
			echo "$(YELLOW)Deploy completo necessario...$(NC)"; \
			$(ANSIBLE_PLAYBOOK) playbooks/homelab-stack.yml -v; \
			echo "deployment_date=$$(date)" > /tmp/homelab_deployed; \
			echo "$(GREEN)✓ Deploy completo terminato$(NC)"; \
		else \
			echo "$(YELLOW)Deploy incrementale - solo modifiche necessarie...$(NC)"; \
			$(ANSIBLE_PLAYBOOK) playbooks/homelab-stack.yml --check --diff; \
			read -p "Applicare le modifiche rilevate? (y/N): " confirm; \
			if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
				$(ANSIBLE_PLAYBOOK) playbooks/homelab-stack.yml; \
				echo "$(GREEN)✓ Deploy incrementale completato$(NC)"; \
			else \
				echo "$(YELLOW)Deploy saltato$(NC)"; \
			fi; \
		fi; \
	else \
		echo "$(RED)✗ Host non raggiungibili, attendo VM...$(NC)"; \
		echo "$(YELLOW)Attendo 30 secondi per il boot delle VM...$(NC)"; \
		sleep 30; \
		if $(ANSIBLE) all -m ping --one-line 2>/dev/null | grep -q "SUCCESS"; then \
			echo "$(GREEN)✓ Host ora raggiungibili, procedo con deploy...$(NC)"; \
			$(ANSIBLE_PLAYBOOK) playbooks/homelab-stack.yml; \
			echo "deployment_date=$$(date)" > /tmp/homelab_deployed; \
		else \
			echo "$(RED)✗ Host ancora non raggiungibili, controlla configurazione$(NC)"; \
			exit 1; \
		fi; \
	fi

# Deploy completo automatizzato
.PHONY: deploy-complete
deploy-complete: check
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                    DEPLOY AUTOMATIZZATO COMPLETO             ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)Questo processo eseguirà automaticamente:$(NC)"
	@echo "$(GREEN)1.$(NC) Controllo e creazione template Packer (se necessari)"
	@echo "$(GREEN)2.$(NC) Verifica e gestione VM Terraform (creazione/aggiornamento)"
	@echo "$(GREEN)3.$(NC) Deploy completo o incrementale Ansible"
	@echo ""
	@read -p "Confermi l'avvio del deploy automatizzato? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "$(BLUE)▶ FASE 1: Template Packer$(NC)"; \
		$(MAKE) ensure-templates; \
		echo ""; \
		echo "$(BLUE)▶ FASE 2: Infrastruttura Terraform$(NC)"; \
		$(MAKE) terraform-check-and-apply; \
		echo ""; \
		echo "$(BLUE)▶ FASE 3: Configurazione Ansible$(NC)"; \
		$(MAKE) ansible-deploy-smart; \
		echo ""; \
		echo "$(GREEN)╔══════════════════════════════════════════════════════════════╗$(NC)"; \
		echo "$(GREEN)║                   DEPLOY COMPLETATO CON SUCCESSO!            ║$(NC)"; \
		echo "$(GREEN)╚══════════════════════════════════════════════════════════════╝$(NC)"; \
		echo "$(YELLOW)Riepilogo deployment:$(NC)"; \
		cd $(TERRAFORM_DIR) && $(TERRAFORM) output; \
	else \
		echo "$(YELLOW)Deploy automatizzato annullato$(NC)"; \
	fi

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
	@echo -n "$(YELLOW)Checking inventories...$(NC) "
	@if [ -f "$(ANSIBLE_DIR)/inventories/production/hosts" ] && [ -f "$(ANSIBLE_DIR)/inventories/dev/hosts" ]; then \
		echo "$(GREEN)✓ Inventories trovati$(NC)"; \
	else \
		echo "$(RED)✗ Inventories mancanti$(NC)"; exit 1; \
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

# Deploy playbook principale (entrambi gli ambienti)
.PHONY: ansible-deploy
ansible-deploy: ansible-check
	@echo "$(BLUE)=== Deploy Ansible su Entrambi gli Ambienti ===$(NC)"
	@echo "$(YELLOW)Attenzione: Questa operazione configurerà entrambi i server!$(NC)"
	@read -p "Confermi il deploy su PRODUCTION e DEVELOPMENT? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(MAKE) deploy-production && $(MAKE) deploy-development; \
	else \
		echo "$(YELLOW)Operazione annullata$(NC)"; \
	fi

# Deploy solo production
.PHONY: deploy-production
deploy-production: ansible-check
	@echo "$(BLUE)=== 🟢 Deploy PRODUCTION Environment ===$(NC)"
	@echo "$(GREEN)Target: VM-01 (192.168.178.20) - prod.matteobaracetti.com$(NC)"
	@read -p "Confermi il deploy in PRODUCTION? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventories/production/hosts playbooks/homelab-stack.yml; \
	else \
		echo "$(YELLOW)Deploy production annullato$(NC)"; \
	fi

# Deploy solo development
.PHONY: deploy-development
deploy-development: ansible-check
	@echo "$(BLUE)=== 🟡 Deploy DEVELOPMENT Environment ===$(NC)"
	@echo "$(YELLOW)Target: VM-02 (192.168.178.21) - dev.matteobaracetti.com$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventories/dev/hosts playbooks/homelab-stack.yml
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/homelab-stack.yml -e "target_env=production"

# Deploy solo development
.PHONY: deploy-development  
deploy-development: ansible-check
	@echo "$(BLUE)=== 🟡 Deploy DEVELOPMENT Environment ===$(NC)"
	@echo "$(YELLOW)Target: VM-02 (192.168.178.21) - dev.matteobaracetti.com$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/homelab-stack.yml -e "target_env=development"

# Deploy staging (retrocompatibilità)
.PHONY: ansible-deploy-staging
ansible-deploy-staging: deploy-development
	@echo "$(YELLOW)Nota: ansible-deploy-staging è ora alias per deploy-development$(NC)"

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

# ================================================
# MONITORAGGIO E TROUBLESHOOTING
# ================================================

# Status completo del deployment
.PHONY: status-all
status-all:
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                      STATUS HOMELAB                          ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)📋 TEMPLATE PACKER:$(NC)"
	@$(MAKE) check-templates 2>/dev/null || echo "$(RED)Errore controllo template$(NC)"
	@echo ""
	@echo "$(YELLOW)🏗️  INFRASTRUTTURA TERRAFORM:$(NC)"
	@$(MAKE) terraform-status 2>/dev/null || echo "$(RED)Terraform non inizializzato$(NC)"
	@echo ""
	@echo "$(YELLOW)⚙️  SERVIZI ANSIBLE:$(NC)"
	@$(MAKE) status-production
	@$(MAKE) status-development

# Status ambiente production
.PHONY: status-production
status-production:
	@echo "$(GREEN)🟢 PRODUCTION STATUS (VM-01):$(NC)"
	@cd $(ANSIBLE_DIR) && if $(ANSIBLE) -i inventories/production/hosts production -m ping --one-line 2>/dev/null | grep -q "SUCCESS"; then \
		echo "$(GREEN)  ✓ Host raggiungibile$(NC)"; \
		$(ANSIBLE) -i inventories/production/hosts production -m shell -a "docker ps" 2>/dev/null | sed '1d' || echo "$(RED)  ✗ Errore Docker$(NC)"; \
	else \
		echo "$(RED)  ✗ Host non raggiungibile$(NC)"; \
	fi
	@echo ""

# Status ambiente development
.PHONY: status-development
status-development:
	@echo "$(YELLOW)🟡 DEVELOPMENT STATUS (VM-02):$(NC)"
	@cd $(ANSIBLE_DIR) && if $(ANSIBLE) -i inventories/dev/hosts development -m ping --one-line 2>/dev/null | grep -q "SUCCESS"; then \
		echo "$(GREEN)  ✓ Host raggiungibile$(NC)"; \
		$(ANSIBLE) -i inventories/dev/hosts development -m shell -a "docker ps" 2>/dev/null | sed '1d' || echo "$(RED)  ✗ Errore Docker$(NC)"; \
	else \
		echo "$(RED)  ✗ Host non raggiungibile$(NC)"; \
	fi
	@echo ""

# Reset completo (attenzione!)
.PHONY: reset-all
reset-all:
	@echo "$(RED)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(RED)║                        RESET COMPLETO                        ║$(NC)"
	@echo "$(RED)║                      ⚠️  ATTENZIONE! ⚠️                       ║$(NC)"
	@echo "$(RED)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(RED)Questa operazione:$(NC)"
	@echo "$(RED)- Distruggerà tutte le VM Terraform$(NC)"
	@echo "$(RED)- Rimuoverà tutti i file di stato$(NC)"
	@echo "$(RED)- Pulirà cache e file temporanei$(NC)"
	@echo ""
	@read -p "Sei ASSOLUTAMENTE SICURO? (type 'RESET' to confirm): " confirm; \
	if [ "$$confirm" = "RESET" ]; then \
		echo "$(YELLOW)Procedendo con reset completo...$(NC)"; \
		$(MAKE) terraform-destroy; \
		$(MAKE) clean-all; \
		rm -f /tmp/homelab_deployed /tmp/template_check; \
		echo "$(GREEN)Reset completo terminato$(NC)"; \
	else \
		echo "$(YELLOW)Reset annullato$(NC)"; \
	fi

# Test connettività completo
.PHONY: test-connectivity
test-connectivity:
	@echo "$(BLUE)=== Test Connettività Completo ===$(NC)"
	@echo "$(YELLOW)Test connettività Proxmox...$(NC)"
	@PROXMOX_HOST=$$(grep 'proxmox_api_url' $(TERRAFORM_DIR)/terraform.tfvars | sed 's/.*https:\/\/\([^:]*\).*/\1/' 2>/dev/null || echo "192.168.178.70"); \
	if ping -c 3 $$PROXMOX_HOST >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Proxmox ($$PROXMOX_HOST) raggiungibile$(NC)"; \
	else \
		echo "$(RED)✗ Proxmox ($$PROXMOX_HOST) non raggiungibile$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Test connettività VM...$(NC)"
	@cd $(ANSIBLE_DIR) && $(ANSIBLE) all -m ping 2>/dev/null || echo "$(RED)✗ VM non raggiungibili$(NC)"
	@echo ""
	@echo "$(YELLOW)Test servizi web...$(NC)"
	@cd $(ANSIBLE_DIR) && \
	VM_IPS=$$($(ANSIBLE) all -m setup -a "filter=ansible_default_ipv4" 2>/dev/null | grep '"address"' | cut -d'"' -f4 || echo ""); \
	for ip in $$VM_IPS; do \
		if [ ! -z "$$ip" ]; then \
			echo -n "$(YELLOW)Traefik ($$ip:80): $(NC)"; \
			if curl -s -o /dev/null -w "%{http_code}" "http://$$ip" | grep -q "200\|301\|302"; then \
				echo "$(GREEN)✓ Risponde$(NC)"; \
			else \
				echo "$(RED)✗ Non risponde$(NC)"; \
			fi; \
			echo -n "$(YELLOW)Pi-hole ($$ip:8080): $(NC)"; \
			if curl -s -o /dev/null -w "%{http_code}" "http://$$ip:8080" | grep -q "200\|301\|302"; then \
				echo "$(GREEN)✓ Risponde$(NC)"; \
			else \
				echo "$(RED)✗ Non risponde$(NC)"; \
			fi; \
		fi; \
	done

# Logs servizi
.PHONY: logs-services
logs-services:
	@echo "$(BLUE)=== Logs Servizi Homelab ===$(NC)"
	@cd $(ANSIBLE_DIR) && \
	echo "$(YELLOW)Logs Docker Compose:$(NC)"; \
	$(ANSIBLE) all -m shell -a "cd /opt/homelab && docker compose logs --tail=20" 2>/dev/null || echo "$(RED)Errore recupero logs$(NC)"

# ================================================
# GESTIONE PROXMOX VIA API
# ================================================

# Setup API Proxmox
.PHONY: proxmox-api-setup
proxmox-api-setup:
	@echo "$(BLUE)=== Setup API Proxmox VE ===$(NC)"
	@echo "$(YELLOW)Questo script ti guiderà nella configurazione dell'API$(NC)"
	$(ANSIBLE_DIR)/scripts/setup-proxmox-api.sh

# Status via API
.PHONY: proxmox-api-status
proxmox-api-status:
	@echo "$(BLUE)=== Status Proxmox via API ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/proxmox-api-management.yml --tags=status

# Aggiornamento completo via API
.PHONY: proxmox-api-update
proxmox-api-update:
	@echo "$(BLUE)=== Aggiornamento Proxmox via API ===$(NC)"
	@echo "$(YELLOW)Aggiornamento completo usando API REST$(NC)"
	@read -p "Confermi l'aggiornamento via API? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/proxmox-api-update.yml; \
	else \
		echo "$(YELLOW)Aggiornamento annullato$(NC)"; \
	fi

# Manutenzione via API
.PHONY: proxmox-api-maintenance
proxmox-api-maintenance:
	@echo "$(BLUE)=== Manutenzione Proxmox via API ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/proxmox-api-maintenance.yml

# Lista VMs via API
.PHONY: proxmox-api-vms
proxmox-api-vms:
	@echo "$(BLUE)=== Lista VMs/Containers via API ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/proxmox-api-management.yml --tags=vms

# Storage status via API
.PHONY: proxmox-api-storage
proxmox-api-storage:
	@echo "$(BLUE)=== Status Storage via API ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/proxmox-api-management.yml --tags=storage

# Tasks via API
.PHONY: proxmox-api-tasks
proxmox-api-tasks:
	@echo "$(BLUE)=== Tasks Status via API ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/proxmox-api-management.yml --tags=tasks

# Cluster status via API
.PHONY: proxmox-api-cluster
proxmox-api-cluster:
	@echo "$(BLUE)=== Cluster Status via API ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/proxmox-api-management.yml --tags=cluster

# Test aggiornamento automatico via API
.PHONY: proxmox-api-test-auto-update
proxmox-api-test-auto-update:
	@echo "$(BLUE)=== Test Aggiornamento Automatico via API ===$(NC)"
	@if [ -f "$(ANSIBLE_DIR)/scripts/proxmox-api-auto-update.sh" ]; then \
		echo "$(YELLOW)Esecuzione test script API...$(NC)"; \
		sudo $(ANSIBLE_DIR)/scripts/proxmox-api-auto-update.sh; \
	else \
		echo "$(RED)Script API non trovato$(NC)"; \
	fi

# ================================================
# GESTIONE PROXMOX (SSH - Legacy)
# ================================================

# Aggiornamento completo Proxmox
.PHONY: proxmox-update
proxmox-update:
	@echo "$(BLUE)=== Aggiornamento Completo Proxmox ===$(NC)"
	@echo "$(YELLOW)Questo processo eseguirà:$(NC)"
	@echo "$(GREEN)1.$(NC) Backup configurazione"
	@echo "$(GREEN)2.$(NC) Aggiornamento sistema"
	@echo "$(GREEN)3.$(NC) Riavvio automatico (se necessario)"
	@echo "$(GREEN)4.$(NC) Verifica servizi post-aggiornamento"
	@echo ""
	@read -p "Confermi l'aggiornamento completo di Proxmox? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventories/proxmox playbooks/proxmox-update.yml; \
	else \
		echo "$(YELLOW)Aggiornamento annullato$(NC)"; \
	fi

# Aggiornamento rapido Proxmox (senza riavvio)
.PHONY: proxmox-quick-update
proxmox-quick-update:
	@echo "$(BLUE)=== Aggiornamento Rapido Proxmox ===$(NC)"
	@echo "$(YELLOW)Aggiornamento pacchetti senza riavvio$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventories/proxmox playbooks/proxmox-quick-update.yml

# Manutenzione Proxmox
.PHONY: proxmox-maintenance
proxmox-maintenance:
	@echo "$(BLUE)=== Manutenzione e Pulizia Proxmox ===$(NC)"
	@echo "$(YELLOW)Questo processo eseguirà:$(NC)"
	@echo "$(GREEN)•$(NC) Pulizia log files"
	@echo "$(GREEN)•$(NC) Rimozione kernel vecchi"
	@echo "$(GREEN)•$(NC) Pulizia backup vecchi"
	@echo "$(GREEN)•$(NC) Controllo stato servizi"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventories/proxmox playbooks/proxmox-maintenance.yml

# Status Proxmox
.PHONY: proxmox-status
proxmox-status:
	@echo "$(BLUE)=== Status Proxmox VE ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) -i inventories/proxmox playbooks/proxmox-management.yml --tags=status

# Test connettività Proxmox
.PHONY: proxmox-ping
proxmox-ping:
	@echo "$(BLUE)=== Test Connettività Proxmox ===$(NC)"
	cd $(ANSIBLE_DIR) && $(ANSIBLE) -i inventories/proxmox proxmox -m ping

# Menu gestione Proxmox
.PHONY: proxmox-menu
proxmox-menu:
	@echo "$(BLUE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║                    GESTIONE PROXMOX VE                       ║$(NC)"
	@echo "$(BLUE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)🔗 API Management (Raccomandato):$(NC)"
	@echo "$(GREEN) 1.$(NC) Setup API                   - make proxmox-api-setup"
	@echo "$(GREEN) 2.$(NC) Status via API              - make proxmox-api-status"
	@echo "$(GREEN) 3.$(NC) Aggiornamento via API       - make proxmox-api-update"
	@echo "$(GREEN) 4.$(NC) Manutenzione via API        - make proxmox-api-maintenance"
	@echo "$(GREEN) 5.$(NC) Lista VMs via API           - make proxmox-api-vms"
	@echo "$(GREEN) 6.$(NC) Storage status via API      - make proxmox-api-storage"
	@echo "$(GREEN) 7.$(NC) Test auto-update API        - make proxmox-api-test-auto-update"
	@echo ""
	@echo "$(YELLOW)🔧 SSH Management (Legacy):$(NC)"
	@echo "$(GREEN) 8.$(NC) Status via SSH              - make proxmox-status"
	@echo "$(GREEN) 9.$(NC) Aggiornamento via SSH       - make proxmox-update"
	@echo "$(GREEN)10.$(NC) Manutenzione via SSH        - make proxmox-maintenance"
	@echo "$(GREEN)11.$(NC) Setup auto-update SSH       - make proxmox-setup-auto-update"
	@echo ""
	@echo "$(YELLOW)Vantaggi API vs SSH:$(NC)"
	@echo "  ✅ API: Più sicuro, non richiede accesso SSH root"
	@echo "  ✅ API: Monitoraggio dettagliato task e progress"
	@echo "  ✅ API: Accesso a tutte le funzionalità Proxmox"
	@echo "  ⚠️  SSH: Accesso diretto ma meno sicuro"
	@echo ""
	@echo "$(YELLOW)Quick Start:$(NC)"
	@echo "  1. make proxmox-api-setup     # Prima configurazione"
	@echo "  2. make proxmox-api-status    # Test e stato"
	@echo "  3. make proxmox-api-update    # Aggiornamento"

# Setup aggiornamenti automatici
.PHONY: proxmox-setup-auto-update
proxmox-setup-auto-update:
	@echo "$(BLUE)=== Setup Aggiornamenti Automatici Proxmox ===$(NC)"
	@echo "$(YELLOW)Questo processo installerà:$(NC)"
	@echo "$(GREEN)•$(NC) Script di aggiornamento automatico"
	@echo "$(GREEN)•$(NC) Configurazione cron per esecuzione programmata"
	@echo "$(GREEN)•$(NC) Sistema di notifiche email"
	@echo "$(GREEN)•$(NC) Rotazione automatica dei log"
	@echo ""
	@read -p "Confermi l'installazione degli aggiornamenti automatici? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		cd $(ANSIBLE_DIR) && $(ANSIBLE_PLAYBOOK) playbooks/setup-proxmox-auto-update.yml; \
	else \
		echo "$(YELLOW)Setup annullato$(NC)"; \
	fi

# Test aggiornamento automatico
.PHONY: proxmox-test-auto-update
proxmox-test-auto-update:
	@echo "$(BLUE)=== Test Aggiornamento Automatico Proxmox ===$(NC)"
	@if [ -f "$(ANSIBLE_DIR)/scripts/proxmox-auto-update.sh" ]; then \
		echo "$(YELLOW)Esecuzione test script...$(NC)"; \
		sudo $(ANSIBLE_DIR)/scripts/proxmox-auto-update.sh; \
	else \
		echo "$(RED)Script non trovato. Esegui prima: make proxmox-setup-auto-update$(NC)"; \
	fi

# Disabilita aggiornamenti automatici
.PHONY: proxmox-disable-auto-update
proxmox-disable-auto-update:
	@echo "$(BLUE)=== Disabilita Aggiornamenti Automatici ===$(NC)"
	@read -p "Confermi la disabilitazione degli aggiornamenti automatici? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		sudo rm -f /etc/cron.d/proxmox-auto-update; \
		echo "$(GREEN)✓ Aggiornamenti automatici disabilitati$(NC)"; \
	else \
		echo "$(YELLOW)Operazione annullata$(NC)"; \
	fi

# Visualizza log aggiornamenti automatici
.PHONY: proxmox-auto-update-logs
proxmox-auto-update-logs:
	@echo "$(BLUE)=== Log Aggiornamenti Automatici ===$(NC)"
	@if [ -d "/var/log/proxmox-auto-update" ]; then \
		echo "$(YELLOW)Log files disponibili:$(NC)"; \
		ls -la /var/log/proxmox-auto-update/; \
		echo ""; \
		echo "$(YELLOW)Ultimo log:$(NC)"; \
		LATEST_LOG=$$(ls -t /var/log/proxmox-auto-update/auto-update-*.log 2>/dev/null | head -1); \
		if [ ! -z "$$LATEST_LOG" ]; then \
			tail -20 "$$LATEST_LOG"; \
		else \
			echo "$(YELLOW)Nessun log trovato$(NC)"; \
		fi; \
	else \
		echo "$(RED)Directory log non trovata. Esegui prima: make proxmox-setup-auto-update$(NC)"; \
	fi
