#!/usr/bin/env bash
set -euo pipefail

# Exécute la commande llm dans le conteneur workspace
# Les arguments passés au script sont transmis à llm
docker exec -i kanissa-workspace llm "$@"