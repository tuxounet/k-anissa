#!/usr/bin/env bash
set -euo pipefail

# Exécute la commande llm dans le conteneur workspace
# Utilise le template 'anissa' (system prompt) par défaut
# Les arguments passés au script sont transmis à llm
docker exec -i kanissa-workspace llm -t anissa "$@"