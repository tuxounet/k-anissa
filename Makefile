GO_PATH:=$(shell go env GOPATH)
# STACK ?= claude-code-proxy-vertex
# STACK ?= lab
STACK ?= opencode-llama
DEBUG ?=
LAYER ?=
VERB ?=
ARGS ?=

# Construire le flag --debug si DEBUG=1
_DEBUG_FLAG := $(if $(filter 1,$(DEBUG)),--debug,)

up:
	@./anissa/bin/anissa $(_DEBUG_FLAG) up $(STACK)

down:
	@./anissa/bin/anissa $(_DEBUG_FLAG) down $(STACK)

restart:
	@./anissa/bin/anissa $(_DEBUG_FLAG) restart $(STACK)

status:
	@./anissa/bin/anissa $(_DEBUG_FLAG) status $(STACK)

logs:
	@./anissa/bin/anissa $(_DEBUG_FLAG) logs $(STACK)

healthcheck:
	@./anissa/bin/anissa $(_DEBUG_FLAG) healthcheck $(STACK)

shell:
	@./anissa/bin/anissa $(_DEBUG_FLAG) shell $(STACK)

run:
	@./anissa/bin/anissa $(_DEBUG_FLAG) run $(STACK) $(LAYER) $(VERB) $(ARGS)

stacks:
	@./anissa/bin/anissa stacks

layers:
	@./anissa/bin/anissa layers

setup:
	@echo "── Installation des dépendances CLI ──"
	@command -v jq >/dev/null 2>&1 || { echo "Installation de jq..."; sudo apt-get install -y jq 2>/dev/null || brew install jq 2>/dev/null || { echo "Erreur: impossible d'installer jq. Installez-le manuellement."; exit 1; }; }
	@echo "✓ jq $$(jq --version 2>/dev/null)"
	@command -v yq >/dev/null 2>&1 || { echo "Installation de yq..."; sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && sudo chmod +x /usr/local/bin/yq || { echo "Erreur: impossible d'installer yq. Installez-le manuellement : https://github.com/mikefarah/yq"; exit 1; }; }
	@echo "✓ yq $$(yq --version 2>/dev/null)"
	@echo "── Installation du renderer k2 ──"
	$(MAKE) -C ./renderer setup

render:
	${GO_PATH}/bin/k2 apply --inventory ./k2.inventory.yaml

unrender:
	${GO_PATH}/bin/k2 destroy --inventory ./k2.inventory.yaml


claude:
	@./anissa/bin/anissa $(_DEBUG_FLAG) run $(STACK) claude-code-in-container  claude 

workspace:
	@./anissa/bin/anissa $(_DEBUG_FLAG) run $(STACK) ubuntu-workspace  workspace 


llm:
	docker exec kanissa-workspace llm "tell me a very short joke"