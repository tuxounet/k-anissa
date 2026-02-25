#!/usr/bin/env bash
#=============================================================================
# anissa/lib/docker.sh — Utilitaires Docker pour le CLI anIssA
#=============================================================================

# Source les dépendances si pas déjà chargées
if [[ -z "${CYAN:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi
if ! declare -f log_info &>/dev/null; then
  source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

# Vérifie que Docker est installé et le daemon actif
docker_check() {
  if ! command -v docker &>/dev/null; then
    log_fatal "Docker n'est pas installé. Installez Docker 24+ : https://docs.docker.com/get-docker/"
  fi

  if ! docker info &>/dev/null 2>&1; then
    log_fatal "Le daemon Docker n'est pas actif. Démarrez Docker : sudo systemctl start docker"
  fi

  # Vérifier docker compose (plugin v2)
  if ! docker compose version &>/dev/null 2>&1; then
    log_fatal "Le plugin 'docker compose' (v2) n'est pas installé."
  fi
}

# Crée le réseau Docker partagé si inexistant
# Utilise $ANISSA_NETWORK (défaut: anissa)
docker_ensure_network() {
  local network="${ANISSA_NETWORK:-anissa}"

  log_debug "Vérification du réseau Docker '${network}'"
  if ! docker network inspect "$network" &>/dev/null 2>&1; then
    log_detail "Création du réseau Docker '${network}'..."
    if docker network create "$network" &>/dev/null; then
      log_detail "Réseau '${network}' créé"
    else
      log_error "Impossible de créer le réseau Docker '${network}'"
      return 1
    fi
  fi
}

# Exécute docker compose dans le contexte d'un composant
# $1 = chemin du dossier du plan
# $@ = arguments docker compose restants
docker_compose_run() {
  local plan_dir="$1"
  shift

  local compose_file="${plan_dir}/compose.yml"

  if [[ ! -f "$compose_file" ]]; then
    log_error "compose.yml introuvable dans ${plan_dir}"
    return 1
  fi

  # Extraire le nom du projet depuis le dossier (dernier segment)
  local project_name
  project_name=$(basename "$plan_dir")

  log_debug "docker compose -f ${compose_file} --project-name ${project_name} $*"
  docker compose -f "$compose_file" --project-name "$project_name" "$@"
}

# Vérifie si les containers d'un plan sont running
# $1 = chemin du dossier du plan
# Retourne 0 si au moins un service est running, 1 sinon
docker_check_running() {
  local plan_dir="$1"
  local compose_file="${plan_dir}/compose.yml"

  if [[ ! -f "$compose_file" ]]; then
    return 1
  fi

  local project_name
  project_name=$(basename "$plan_dir")

  local running
  running=$(docker compose -f "$compose_file" --project-name "$project_name" ps --format json 2>/dev/null \
    | grep -c '"running"' 2>/dev/null || true)

  [[ "$running" -gt 0 ]]
}

# Retourne le statut d'un plan (UP, DOWN, DEGRADED)
# $1 = chemin du dossier du plan
docker_get_status() {
  local plan_dir="$1"
  local compose_file="${plan_dir}/compose.yml"

  if [[ ! -f "$compose_file" ]]; then
    echo "DOWN"
    return
  fi

  local project_name
  project_name=$(basename "$plan_dir")

  local ps_output
  ps_output=$(docker compose -f "$compose_file" --project-name "$project_name" ps --format json 2>/dev/null || true)

  if [[ -z "$ps_output" ]]; then
    echo "DOWN"
    return
  fi

  local total running
  total=$(echo "$ps_output" | wc -l)
  running=$(echo "$ps_output" | grep -c '"running"' || true)

  if [[ "$running" -eq 0 ]]; then
    echo "DOWN"
  elif [[ "$running" -eq "$total" ]]; then
    echo "UP"
  else
    echo "DEGRADED"
  fi
}
