#!/usr/bin/env bash
#=============================================================================
# Gestion de la configuration / profils
#
# Un profil (starter) est un fichier profile.env contenant :
#   - KANISSA_DESCRIPTION : description du profil
#   - KANISSA_COMPONENTS  : liste ordonnée des composants à activer
#                           (format : "layer/component" séparés par des espaces)
#   - Variables d'environnement spécifiques au profil
#=============================================================================

_CURRENT_PROFILE=""
_CURRENT_PROFILE_DIR=""

# Charge un profil
config_load() {
  local profile_name="$1"
  _CURRENT_PROFILE_DIR="$KANISSA_STARTERS/$profile_name"

  if [[ ! -d "$_CURRENT_PROFILE_DIR" ]]; then
    log_error "Profil introuvable : $profile_name"
    log_info "Profils disponibles :"
    ls -1 "$KANISSA_STARTERS" 2>/dev/null | while read -r d; do
      [[ -f "$KANISSA_STARTERS/$d/profile.env" ]] && printf "  - %s\n" "$d"
    done
    exit 1
  fi

  if [[ ! -f "$_CURRENT_PROFILE_DIR/profile.env" ]]; then
    log_error "Fichier profile.env manquant dans $profile_name"
    exit 1
  fi

  _CURRENT_PROFILE="$profile_name"

  # Charger les variables d'environnement du profil
  set -a
  source "$_CURRENT_PROFILE_DIR/profile.env"
  set +a

  # Créer le dossier de données si nécessaire
  mkdir -p "$KANISSA_DATA/$profile_name"

  log_info "Profil chargé : ${CYAN}${profile_name}${RESET}"
  log_info "Composants :"
  local _comp
  for _comp in ${KANISSA_COMPONENTS:-}; do
    [[ "$_comp" =~ ^#.*$ ]] && continue
    [[ -z "$_comp" ]] && continue
    printf "    ${CYAN}%s${RESET}\n" "$_comp"
  done
}

# Remplit un tableau avec la liste des composants du profil courant
# Usage : config_get_components my_array
config_get_components() {
  local -n _arr=$1
  _arr=()

  if [[ -z "${KANISSA_COMPONENTS:-}" ]]; then
    log_warn "Aucun composant défini dans le profil"
    return 0
  fi

  # Lecture ligne par ligne ou espace par espace
  local comp
  for comp in $KANISSA_COMPONENTS; do
    # Ignorer les commentaires et lignes vides
    [[ "$comp" =~ ^#.*$ ]] && continue
    [[ -z "$comp" ]] && continue
    _arr+=("$comp")
  done
}

# Retourne le chemin du profil courant
config_get_profile_dir() {
  echo "$_CURRENT_PROFILE_DIR"
}

# Retourne le nom du profil courant
config_get_profile_name() {
  echo "$_CURRENT_PROFILE"
}
