#!/usr/bin/env bash
#=============================================================================
# Couleurs et formatage terminal
#=============================================================================

export RESET=$'\033[0m'
export BOLD=$'\033[1m'
export DIM=$'\033[2m'

export RED=$'\033[31m'
export GREEN=$'\033[32m'
export YELLOW=$'\033[33m'
export BLUE=$'\033[34m'
export CYAN=$'\033[36m'
export WHITE=$'\033[37m'

# Désactiver les couleurs si pas de terminal
if [[ ! -t 1 ]]; then
  RESET="" BOLD="" DIM=""
  RED="" GREEN="" YELLOW="" BLUE="" CYAN="" WHITE=""
fi
