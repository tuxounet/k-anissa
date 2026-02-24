#!/usr/bin/env bash
#=============================================================================
# LLM Proxy — Hooks de couche
#=============================================================================

post_start() {
  local comp_dir="$1"
  local port="${LITELLM_PORT:-4000}"

  local key="${LITELLM_MASTER_KEY:-sk-kanissa-dev}"
  log_step "Attente que LiteLLM soit prêt sur le port ${port}..."
  local retries=20
  while (( retries > 0 )); do
    if curl -sf -H "Authorization: Bearer ${key}" "http://localhost:${port}/health" &>/dev/null; then
      log_success "  LiteLLM proxy prêt"
      return 0
    fi
    sleep 2
    (( retries-- ))
  done
  log_warn "LiteLLM n'a pas répondu dans les temps"
}
