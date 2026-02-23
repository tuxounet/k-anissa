#!/usr/bin/env bash
#=============================================================================
# Gestion des couches (layers)
#
# Chaque composant est un dossier contenant :
#   - compose.yml   (obligatoire) — définition Docker Compose
#   - layer.sh      (optionnel)   — hooks : pre_start, post_start,
#                                           pre_stop,  post_stop, status
#   - .env          (optionnel)   — variables d'environnement
#=============================================================================

# Résout le chemin complet d'un composant depuis sa ref "layer/component"
_layer_resolve_path() {
  local ref="$1"
  local layer_name="${ref%%/*}"
  local comp_name="${ref#*/}"
  echo "$KANISSA_LAYERS/$layer_name/$comp_name"
}

# Charge les hooks d'un composant (si layer.sh existe)
_layer_load_hooks() {
  local comp_dir="$1"
  # Réinitialiser les hooks à vide
  pre_start()  { :; }
  post_start() { :; }
  pre_stop()   { :; }
  post_stop()  { :; }

  if [[ -f "$comp_dir/layer.sh" ]]; then
    source "$comp_dir/layer.sh"
  fi
}

# Démarre un composant
# $1 = référence "layer/component"
layer_start() {
  local ref="$1"
  local comp_dir
  comp_dir="$(_layer_resolve_path "$ref")"

  if [[ ! -f "$comp_dir/compose.yml" ]]; then
    log_warn "Composant ${YELLOW}${ref}${RESET} : compose.yml introuvable, ignoré"
    return 0
  fi

  log_step "Démarrage de ${CYAN}${ref}${RESET}"

  _layer_load_hooks "$comp_dir"

  # Injecter les variables globales dans l'environnement compose
  export KANISSA_NETWORK
  export KANISSA_DATA

  pre_start "$comp_dir"

  log_info "  docker compose up -d ${DIM}(${ref})${RESET}"
  docker_compose_run "$comp_dir" up -d --remove-orphans 2>&1 | while read -r line; do
    printf "    ${DIM}%s${RESET}\n" "$line"
  done

  post_start "$comp_dir"

  log_success "  ${ref} démarré"
}

# Arrête un composant
layer_stop() {
  local ref="$1"
  local comp_dir
  comp_dir="$(_layer_resolve_path "$ref")"

  if [[ ! -f "$comp_dir/compose.yml" ]]; then
    return 0
  fi

  log_step "Arrêt de ${CYAN}${ref}${RESET}"

  _layer_load_hooks "$comp_dir"

  pre_stop "$comp_dir"

  log_info "  docker compose down ${DIM}(${ref})${RESET}"
  docker_compose_run "$comp_dir" down --remove-orphans 2>&1 | while read -r line; do
    printf "    ${DIM}%s${RESET}\n" "$line"
  done

  post_stop "$comp_dir"

  log_success "  ${ref} arrêté"
}

# Affiche le statut d'un composant
layer_status() {
  local ref="$1"
  local comp_dir
  comp_dir="$(_layer_resolve_path "$ref")"

  if [[ ! -f "$comp_dir/compose.yml" ]]; then
    printf "  %-40s ${DIM}%-15s${RESET}\n" "$ref" "non configuré"
    return 0
  fi

  local running
  running=$(docker_compose_run "$comp_dir" ps --format '{{.State}}' 2>/dev/null | grep -c "running" || true)
  local total
  total=$(docker_compose_run "$comp_dir" ps --format '{{.State}}' 2>/dev/null | wc -l || echo 0)

  if [[ "$total" -eq 0 ]]; then
    printf "  %-40s ${DIM}%-15s${RESET}\n" "$ref" "arrêté"
  elif [[ "$running" -eq "$total" ]]; then
    printf "  %-40s ${GREEN}%-15s${RESET}\n" "$ref" "actif ($running/$total)"
  else
    printf "  %-40s ${YELLOW}%-15s${RESET}\n" "$ref" "partiel ($running/$total)"
  fi
}

# Affiche les logs d'un composant
layer_logs() {
  local ref="$1"
  local comp_dir
  comp_dir="$(_layer_resolve_path "$ref")"

  if [[ ! -f "$comp_dir/compose.yml" ]]; then
    log_warn "Composant ${YELLOW}${ref}${RESET} : compose.yml introuvable"
    return 0
  fi

  docker_compose_run "$comp_dir" logs --tail=50 --follow
}

# Collecte les liens d'accès d'un composant
# $1 = référence "layer/component"
# Affiche les liens sur stdout (un par ligne : "label|url")
layer_get_links() {
  local ref="$1"
  local comp_dir
  comp_dir="$(_layer_resolve_path "$ref")"

  if [[ ! -f "$comp_dir/links.env" ]]; then
    return 0
  fi

  # links.env format: LABEL=url (variables d'env résolues)
  while IFS='=' read -r label url; do
    # Ignorer commentaires et lignes vides
    [[ -z "$label" || "$label" =~ ^# ]] && continue
    # Résoudre les variables d'environnement dans l'URL
    url=$(eval echo "$url")
    echo "${label}|${url}"
  done < "$comp_dir/links.env"
}
