#!/usr/bin/env bash
#=============================================================================
# Workspace conteneurisé — Hooks de couche
#=============================================================================

pre_start() {
  local comp_dir="$1"
  mkdir -p "${KANISSA_DATA}/workspace"
  mkdir -p "${KANISSA_DATA}/claude-code"
  mkdir -p "${KANISSA_DATA}/ssh"

  # Générer la paire de clés SSH si elle n'existe pas
  if [[ ! -f "${KANISSA_DATA}/ssh/id_ed25519" ]]; then
    log_info "  Génération de la paire de clés SSH..."
    ssh-keygen -t ed25519 -f "${KANISSA_DATA}/ssh/id_ed25519" -N "" -q
    log_success "  Paire de clés SSH générée dans ${KANISSA_DATA}/ssh/"
  fi

  log_info "  Dossiers de données workspace prêts"
}

post_start() {
  local comp_dir="$1"

  log_step "Attente que le workspace soit prêt..."
  local retries=15
  while (( retries > 0 )); do
    if docker exec kanissa-workspace test -f /root/.claude/settings.json 2>/dev/null; then
      log_success "  Workspace conteneurisé prêt"

      # Afficher les serveurs MCP configurés
      local mcp_servers
      mcp_servers=$(docker exec kanissa-workspace jq -r '.mcpServers | keys[]' /root/.claude/settings.json 2>/dev/null || true)
      if [[ -n "$mcp_servers" ]]; then
        log_info "  Serveurs MCP configurés :"
        while read -r srv; do
          [[ -n "$srv" ]] && printf "    ${CYAN}%s${RESET}\n" "$srv"
        done <<< "$mcp_servers"
      fi

      printf "\n"
      log_info "  ${BOLD}Lancer Claude Code :${RESET}"
      printf "    ${CYAN}docker exec -it kanissa-workspace claude${RESET}\n\n"
      return 0
    fi
    sleep 2
    (( retries-- ))
  done
  log_warn "Le workspace n'a pas répondu dans les temps"
}
