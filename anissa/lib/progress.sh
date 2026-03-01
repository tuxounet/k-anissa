#!/usr/bin/env bash
#=============================================================================
# anissa/lib/progress.sh — Affichage de progression pour le CLI anIssA
#=============================================================================

# Source les couleurs si pas déjà chargées
if [[ -z "${CYAN:-}" ]]; then
  source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

# Affiche la bannière d'opération
# $1 = verbe (up, down, status, healthcheck, restart, logs)
# $2 = nom de la stack
# $3 = nombre total de layers
progress_banner() {
  local verb="$1"
  local stack="$2"
  local total="${3:-0}"

  local label=""
  [[ "$total" -gt 0 ]] && label=" ($total layers)"

  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  anIssA ▶ ${verb} ${CYAN}${stack}${RESET}${BOLD}${label}${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
}

# Affiche le début d'une étape layer
# $1 = index courant (1-based)
# $2 = total layers
# $3 = verbe visuel (▶ Démarrage, ■ Arrêt, ♥ Vérification)
# $4 = référence layer/plan
progress_step_start() {
  local current="$1"
  local total="$2"
  local verb_visual="$3"
  local ref="$4"

  echo -e "${BOLD}[${current}/${total}]${RESET} ${CYAN}${verb_visual}${RESET} de ${BOLD_CYAN}${ref}${RESET}"
}

# Affiche un détail/sous-action (en DIM)
# $1 = message
progress_detail() {
  echo -e "       ${DIM}↳ $1${RESET}"
}

# Affiche le succès d'une étape
# $1 = nom du plan
# $2 = message ("démarré", "arrêté", etc.)
progress_step_ok() {
  local plan="$1"
  local message="$2"

  echo -e "       ${GREEN}✓${RESET} ${plan} ${message}"
  echo ""
}

# Affiche l'échec d'une étape
# $1 = nom du plan
# $2 = message d'erreur (optionnel)
progress_step_fail() {
  local plan="$1"
  local message="${2:-échec}"

  echo -e "       ${RED}✗${RESET} ${plan} — ${RED}${message}${RESET}"
  echo ""
}

# Affiche le skip d'une étape
# $1 = nom du plan
# $2 = raison
progress_step_skip() {
  local plan="$1"
  local reason="${2:-ignoré}"

  echo -e "       ${YELLOW}⊘${RESET} ${plan} — ${YELLOW}${reason}${RESET}"
  echo ""
}

# Affiche le résumé de fin d'opération
# $1 = verbe passé ("démarrée", "arrêtée")
# $2 = nom de la stack
# $3 = nombre de succès
# $4 = nombre total
# $5 = (optionnel) tableau associatif des échecs "layer|message"
progress_summary() {
  local verb_past="$1"
  local stack="$2"
  local success_count="$3"
  local total="$4"
  shift 4

  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

  if [[ "$success_count" -eq "$total" ]]; then
    echo -e "  ${GREEN}✓${RESET} Stack ${CYAN}${stack}${RESET} ${verb_past} ${GREEN}(${success_count}/${total} layers)${RESET}"
  else
    echo -e "  ${YELLOW}⚠${RESET} Stack ${CYAN}${stack}${RESET} partiellement ${verb_past} ${YELLOW}(${success_count}/${total} layers)${RESET}"
    # Afficher les échecs passés en arguments restants
    for failure in "$@"; do
      local f_layer="${failure%%|*}"
      local f_msg="${failure##*|}"
      echo -e "  ${RED}✗${RESET} ${f_layer} — ${RED}${f_msg}${RESET}"
    done
  fi

  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
}

# Affiche le tableau des liens d'accès
# $1 = contenu agrégé des liens (label=url par ligne)
progress_links_table() {
  local links_content="$1"

  if [[ -z "$links_content" ]]; then
    return
  fi

  echo -e "  ${BOLD}Accès aux services :${RESET}"
  echo -e "  ──────────────────────────── ──────────────────────────────"

  while IFS= read -r line; do
    # Ignorer les commentaires et lignes vides
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    local label="${line%%=*}"
    local url="${line#*=}"

    # Résoudre les variables d'environnement dans l'URL
    url=$(eval echo "$url" 2>/dev/null || echo "$url")

    printf "  %-30s %s\n" "$label" "$url"
  done <<< "$links_content"

  echo ""
}

# Affiche le tableau de statut coloré
# Stdin = lignes "layer/plan|STATUS" ou "layer/plan|STATUS|URL" 
progress_status_table() {
  echo ""
  echo -e "  ${BOLD}LAYER                                    STATUT     URL${RESET}"
  echo -e "  ──────────────────────────────────────── ────────── ──────────────────────────"

  while IFS='|' read -r layer_ref status url; do
    # Ignorer les lignes vides
    [[ -z "$layer_ref" ]] && continue

    local status_display=""
    case "$status" in
      UP)       status_display="${GREEN}✓ UP${RESET}" ;;
      DOWN)     status_display="${RED}✗ DOWN${RESET}" ;;
      DEGRADED) status_display="${YELLOW}⚠ DEGRADED${RESET}" ;;
      SHELL)    status_display="${CYAN}◆ SHELL${RESET}" ;;
      *)        status_display="${DIM}? ${status}${RESET}" ;;
    esac

    local url_display=""
    if [[ -n "${url:-}" ]]; then
      url_display="${DIM}${url}${RESET}"
    fi

    printf "  %-40s %b  %b\n" "$layer_ref" "$status_display" "$url_display"
  done

  echo ""
}
