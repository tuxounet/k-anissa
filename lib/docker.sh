#!/usr/bin/env bash
#=============================================================================
# Helpers Docker
#=============================================================================

export KANISSA_NETWORK="kanissa"

# Crée le réseau Docker partagé s'il n'existe pas
docker_ensure_network() {
  if ! docker network inspect "$KANISSA_NETWORK" &>/dev/null; then
    log_step "Création du réseau Docker ${CYAN}${KANISSA_NETWORK}${RESET}"
    docker network create "$KANISSA_NETWORK" >/dev/null
  fi
}

# Vérifie que Docker est disponible
docker_check() {
  if ! command -v docker &>/dev/null; then
    log_error "Docker n'est pas installé ou pas dans le PATH"
    exit 1
  fi
  if ! docker info &>/dev/null; then
    log_error "Le daemon Docker ne répond pas. Est-il démarré ?"
    exit 1
  fi
}

# Lance docker compose pour un composant donné
# $1 = chemin vers le dossier du composant
# $2... = arguments docker compose
docker_compose_run() {
  local comp_dir="$1"
  shift
  local project_name
  project_name="kanissa-$(basename "$comp_dir")"

  local env_file=""
  if [[ -f "$comp_dir/.env" ]]; then
    env_file="--env-file $comp_dir/.env"
  fi

  docker compose \
    --project-name "$project_name" \
    --file "$comp_dir/compose.yml" \
    $env_file \
    "$@"
}
