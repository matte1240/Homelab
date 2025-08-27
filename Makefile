# Makefile per la creazione automatica dei template VM Proxmox
# Usa: make <target> per eseguire le operazioni

# Variabili di configurazione
PACKER := packer
CREDENTIALS := credentials.pkr.hcl
PACKER_LOG_LEVEL := 1

# Colori per output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Template disponibili
UBUNTU_TEMPLATE := ubuntu-server-noble
DEBIAN_TRIXIE_TEMPLATE := debian-server-trixie

# Target predefinito
.DEFAULT_GOAL := help

# Aiuto
.PHONY: help
help:
	@echo "$(BLUE)=== Makefile per Template VM Proxmox ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Target disponibili:$(NC)"
	@echo "  $(GREEN)help$(NC)                    - Mostra questo aiuto"
	@echo "  $(GREEN)check$(NC)                   - Verifica prerequisiti e configurazione"
	@echo "  $(GREEN)validate-all$(NC)            - Valida tutti i template"
	@echo "  $(GREEN)build-all$(NC)               - Costruisce tutti i template"
	@echo "  $(GREEN)clean$(NC)                   - Pulisce i file temporanei"
	@echo ""
	@echo "$(YELLOW)Template specifici:$(NC)"
	@echo "  $(GREEN)validate-ubuntu$(NC)         - Valida template Ubuntu Noble"
	@echo "  $(GREEN)build-ubuntu$(NC)            - Costruisce template Ubuntu Noble"
	@echo "  $(GREEN)validate-debian-trixie$(NC)  - Valida template Debian Trixie"
	@echo "  $(GREEN)build-debian-trixie$(NC)     - Costruisce template Debian Trixie"
	@echo ""
	@echo "$(YELLOW)Utilità:$(NC)"
	@echo "  $(GREEN)show-ips$(NC)                - Mostra configurazione IP"
	@echo ""
	@echo "$(YELLOW)Esempi:$(NC)"
	@echo "  make check                    # Verifica tutto prima di iniziare"
	@echo "  make build-ubuntu             # Costruisce solo Ubuntu"
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
	@echo -n "$(YELLOW)Checking credentials...$(NC) "
	@if [ -f "$(CREDENTIALS)" ]; then \
		echo "$(GREEN)✓ File credenziali trovato$(NC)"; \
	else \
		echo "$(RED)✗ File $(CREDENTIALS) non trovato$(NC)"; \
		echo "$(YELLOW)Esegui: cp credentials.pkr.hcl.example credentials.pkr.hcl$(NC)"; \
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
	@echo "$(YELLOW)Ubuntu template:$(NC) $(shell grep http_bind_address $(UBUNTU_TEMPLATE)/$(UBUNTU_TEMPLATE).pkr.hcl | grep -oP '"\K[^"]+')"
	@if [ -f "$(DEBIAN_TRIXIE_TEMPLATE)/$(DEBIAN_TRIXIE_TEMPLATE).pkr.hcl" ]; then \
		echo "$(YELLOW)Debian Trixie:$(NC) $(shell grep http_bind_address $(DEBIAN_TRIXIE_TEMPLATE)/$(DEBIAN_TRIXIE_TEMPLATE).pkr.hcl | grep -oP '"\K[^"]+')"; \
	fi

# Validazione template
.PHONY: validate-ubuntu
validate-ubuntu:
	@echo "$(BLUE)=== Validazione Template Ubuntu ===$(NC)"
	cd $(UBUNTU_TEMPLATE) && $(PACKER) validate -var-file="../$(CREDENTIALS)" $(UBUNTU_TEMPLATE).pkr.hcl

.PHONY: validate-debian-trixie
validate-debian-trixie:
	@echo "$(BLUE)=== Validazione Template Debian Trixie ===$(NC)"
	cd $(DEBIAN_TRIXIE_TEMPLATE) && $(PACKER) validate -var-file="../$(CREDENTIALS)" $(DEBIAN_TRIXIE_TEMPLATE).pkr.hcl

.PHONY: validate-all
validate-all: validate-ubuntu validate-debian-trixie
	@echo "$(GREEN)=== Tutti i template validati con successo ===$(NC)"

# Build template
.PHONY: build-ubuntu
build-ubuntu: validate-ubuntu
	@echo "$(BLUE)=== Build Template Ubuntu Noble ===$(NC)"
	cd $(UBUNTU_TEMPLATE) && PACKER_LOG=$(PACKER_LOG_LEVEL) $(PACKER) build -var-file="../$(CREDENTIALS)" $(UBUNTU_TEMPLATE).pkr.hcl

.PHONY: build-debian-trixie
build-debian-trixie: validate-debian-trixie
	@echo "$(BLUE)=== Build Template Debian Trixie ===$(NC)"
	cd $(DEBIAN_TRIXIE_TEMPLATE) && PACKER_LOG=$(PACKER_LOG_LEVEL) $(PACKER) build -var-file="../$(CREDENTIALS)" $(DEBIAN_TRIXIE_TEMPLATE).pkr.hcl

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

# Pulizia
.PHONY: clean
clean:
	@echo "$(BLUE)=== Pulizia file temporanei ===$(NC)"
	@find . -name "*.log" -type f -delete
	@find . -name "packer_cache" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name ".packer" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)Pulizia completata$(NC)"

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
