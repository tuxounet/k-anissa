#!/usr/bin/env bash
#=============================================================================
# Ollama embarqué — Hooks de couche
#=============================================================================

pre_start() {
  local comp_dir="$1"
  mkdir -p "${KANISSA_DATA}/ollama"
  log_info "  Dossier de données Ollama prêt"
}

post_start() {
  local comp_dir="$1"
  local port="${OLLAMA_PORT:-11434}"

  log_step "Attente qu'Ollama soit prêt sur le port ${port}..."
  local retries=30
  while (( retries > 0 )); do
    if curl -sf "http://localhost:${port}/api/tags" &>/dev/null; then
      log_success "  Ollama est prêt"
      
      # Tirer les modèles par défaut si configurés
      if [[ -n "${OLLAMA_MODELS:-}" ]]; then
        for model in $OLLAMA_MODELS; do
          log_step "Pull du modèle ${CYAN}${model}${RESET}"
          docker exec kanissa-ollama ollama pull "$model" 2>&1 | tail -1
        done
      fi
      return 0
    fi
    sleep 2
    (( retries-- ))
  done
  log_warn "Ollama n'a pas répondu dans les temps"
}
