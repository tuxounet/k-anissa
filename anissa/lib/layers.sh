#!/usr/bin/env bash
#=============================================================================
# anissa/lib/layers.sh — Résolution de chemin, exécution des verbes et hooks
#=============================================================================

# Source les dépendances si pas déjà chargées
if ! declare -f log_info &>/dev/null; then
  source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi
if ! declare -f docker_compose_run &>/dev/null; then
  source "$(dirname "${BASH_SOURCE[0]}")/docker.sh"
fi

# Résout le chemin complet d'un plan
# $1 = layer path relatif (ex: "layers/2.locals-subscriptions")
# $2 = nom du plan (ex: "ollama-registry")
# Sortie : chemin absolu vers le dossier du plan
layer_resolve_path() {
  local layer_path="$1"
  local plan="$2"
  local resolved="${ANISSA_ROOT}/${layer_path}/${plan}"

  log_debug "Résolution chemin: ${layer_path}/${plan} -> ${resolved}"
  echo "$resolved"
}

# Démarre un composant
# $1 = chemin absolu du plan
# Retourne 0 en cas de succès, 1 en cas d'échec
layer_start() {
  local plan_dir="$1"

  if [[ ! -f "${plan_dir}/compose.yml" ]]; then
    return 2  # Signal de skip
  fi

  local output
  log_debug "Exécution: docker compose up -d --remove-orphans dans ${plan_dir}"
  output=$(docker_compose_run "$plan_dir" up -d --remove-orphans 2>&1) || {
    # En cas d'erreur, afficher les détails
    if [[ -n "$output" ]]; then
      echo -e "       ${DIM}${RED}${output}${RESET}" >&2
    fi
    return 1
  }

  return 0
}

# Arrête un composant
# $1 = chemin absolu du plan
layer_stop() {
  local plan_dir="$1"

  if [[ ! -f "${plan_dir}/compose.yml" ]]; then
    return 2  # Signal de skip
  fi

  local output
  log_debug "Exécution: docker compose down dans ${plan_dir}"
  output=$(docker_compose_run "$plan_dir" down 2>&1) || {
    if [[ -n "$output" ]]; then
      echo -e "       ${DIM}${RED}${output}${RESET}" >&2
    fi
    return 1
  }

  return 0
}

# Affiche le statut d'un composant
# $1 = chemin absolu du plan
# Sortie : UP, DOWN ou DEGRADED
layer_status() {
  local plan_dir="$1"

  if [[ ! -f "${plan_dir}/compose.yml" ]]; then
    echo "DOWN"
    return
  fi

  docker_get_status "$plan_dir"
}

# Affiche les logs d'un composant
# $1 = chemin absolu du plan
# $2 = (optionnel) options supplémentaires pour docker compose logs
layer_logs() {
  local plan_dir="$1"
  shift

  if [[ ! -f "${plan_dir}/compose.yml" ]]; then
    log_warn "Pas de compose.yml dans ${plan_dir}"
    return 1
  fi

  docker_compose_run "$plan_dir" logs -f "$@"
}

# Exécute un healthcheck sur un composant
# $1 = chemin absolu du plan
# Retourne : "OK", "DEGRADED", "DOWN"
layer_healthcheck() {
  local plan_dir="$1"

  if [[ ! -f "${plan_dir}/compose.yml" ]]; then
    echo "DOWN"
    return
  fi

  # Vérifier que les containers tournent
  local status
  status=$(docker_get_status "$plan_dir")

  if [[ "$status" == "DOWN" ]]; then
    echo "DOWN"
    return
  fi

  # Exécuter le hook healthcheck si déclaré
  local hook_result
  if layer_run_hook "$plan_dir" "healthcheck" 2>/dev/null; then
    echo "$status"
  else
    # Si le hook échoue mais les containers tournent
    if [[ "$status" == "UP" ]]; then
      echo "DEGRADED"
    else
      echo "$status"
    fi
  fi
}

# Ouvre un shell dans un composant
# $1 = chemin absolu du plan
layer_shell() {
  local plan_dir="$1"

  if [[ ! -f "${plan_dir}/compose.yml" ]]; then
    log_error "Pas de compose.yml dans ${plan_dir}"
    return 1
  fi

  # Récupérer le premier service défini dans le compose
  local service
  service=$(yq '.services | keys | .[0]' "${plan_dir}/compose.yml" 2>/dev/null)

  if [[ -z "$service" || "$service" == "null" ]]; then
    log_error "Aucun service trouvé dans ${plan_dir}/compose.yml"
    return 1
  fi

  docker_compose_run "$plan_dir" exec "$service" bash 2>/dev/null \
    || docker_compose_run "$plan_dir" exec "$service" sh
}

# Retourne les liens d'accès d'un composant
# $1 = chemin absolu du plan
# Sortie : contenu du links.env (label=url par ligne) ou vide
layer_get_links() {
  local plan_dir="$1"
  local links_file="${plan_dir}/links.env"

  if [[ -f "$links_file" ]]; then
    cat "$links_file"
  fi
}

# Charge et exécute un hook depuis le k2.apply.yaml
# $1 = chemin du dossier du plan
# $2 = nom du hook (pre_start, post_start, pre_stop, post_stop, healthcheck)
# Retourne 0 si le hook s'exécute avec succès (ou n'existe pas), 1 si échec
layer_run_hook() {
  local plan_dir="$1"
  local hook_name="$2"

  local apply_file="${plan_dir}/k2.apply.yaml"

  # Si pas de fichier k2.apply.yaml, pas de hooks
  if [[ ! -f "$apply_file" ]]; then
    return 0
  fi

  # Extraire le hook depuis le YAML
  local hook_content
  hook_content=$(yq ".k2.body.hooks.${hook_name} // \"\"" "$apply_file" 2>/dev/null)

  # Si le hook est vide ou null, rien à faire
  if [[ -z "$hook_content" || "$hook_content" == "null" || "$hook_content" == '""' ]]; then
    return 0
  fi

  # Exécuter le hook dans le contexte du dossier du plan
  log_detail "Hook ${hook_name}..."
  log_debug "Contenu du hook ${hook_name}: ${hook_content}"
  (
    cd "$plan_dir" || exit 1
    bash -c "$hook_content"
  )
}

# Liste les verbes disponibles pour un plan
# $1 = chemin absolu du plan
# Sortie : liste des noms de verbes (un par ligne, sans extension .sh)
layer_list_verbs() {
  local plan_dir="$1"
  local verbs_dir="${plan_dir}/verbs"

  if [[ ! -d "$verbs_dir" ]]; then
    return
  fi

  for verb_file in "${verbs_dir}"/*.sh; do
    [[ -f "$verb_file" ]] || continue
    basename "$verb_file" .sh
  done
}

# Exécute un verbe spécifique sur un plan
# $1 = chemin absolu du plan
# $2 = nom du verbe (sans .sh)
# $@ = arguments supplémentaires passés au script du verbe
# Retourne 0 en cas de succès, 1 en cas d'échec
layer_run_verb() {
  local plan_dir="$1"
  local verb_name="$2"
  shift 2
  local verb_args=("$@")

  local verb_script="${plan_dir}/verbs/${verb_name}.sh"

  if [[ ! -f "$verb_script" ]]; then
    log_error "Verbe '${verb_name}' introuvable dans ${plan_dir}/verbs/"
    local available
    available=$(layer_list_verbs "$plan_dir")
    if [[ -n "$available" ]]; then
      log_info "Verbes disponibles : $(echo "$available" | tr '\n' ' ')"
    fi
    return 1
  fi

  if [[ ! -x "$verb_script" ]]; then
    chmod +x "$verb_script"
  fi

  log_debug "Exécution du verbe: ${verb_script} ${verb_args[*]:-}"
  (
    cd "$plan_dir" || exit 1
    bash "$verb_script" "${verb_args[@]:-}"
  )
}
