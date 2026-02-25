#!/usr/bin/env bash
#=============================================================================
# anissa/lib/logging.sh — Fonctions de logging pour le CLI anIssA
#=============================================================================

# Source les couleurs si pas déjà chargées
if [[ -z "${CYAN:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

# Log informatif (cyan)
log_info() {
  echo -e "${CYAN}ℹ${RESET} $*"
}

# Log de succès (vert)
log_success() {
  echo -e "${GREEN}✓${RESET} $*"
}

# Log d'avertissement (jaune)
log_warn() {
  echo -e "${YELLOW}⚠${RESET} $*"
}

# Log d'erreur (rouge)
log_error() {
  echo -e "${RED}✗${RESET} $*" >&2
}

# Log d'étape courante (bold)
log_step() {
  echo -e "${BOLD}▶${RESET} $*"
}

# Log de détail secondaire (dim)
log_detail() {
  echo -e "       ${DIM}↳ $*${RESET}"
}

# Log de débogage (magenta, uniquement si ANISSA_DEBUG=1)
log_debug() {
  if [[ "${ANISSA_DEBUG:-0}" == "1" ]]; then
    echo -e "${DIM}${CYAN}🔍${RESET} ${DIM}$*${RESET}"
  fi
}

# Log fatal : affiche l'erreur et quitte
log_fatal() {
  log_error "$@"
  exit 1
}
