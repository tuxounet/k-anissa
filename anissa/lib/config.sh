#!/usr/bin/env bash
#=============================================================================
# anissa/lib/config.sh — Parsing des stacks YAML et cascade de config
#=============================================================================

# Source les dépendances si pas déjà chargées
if ! declare -f log_info &>/dev/null; then
  source "$(dirname "${BASH_SOURCE[0]}")/logging.sh"
fi

# Vérifie que yq est disponible
_config_check_yq() {
  if ! command -v yq &>/dev/null; then
    log_fatal "yq (v4+) n'est pas installé. Installez-le : https://github.com/mikefarah/yq"
  fi
}

# ── Variables globales du module ─────────────────────────────────────────────
# Stocke les layers chargées depuis la stack
declare -a _STACK_LAYERS_PATH=()
declare -a _STACK_LAYERS_PLAN=()
declare -a _STACK_LAYERS_ENV=()
_STACK_NAME=""
_STACK_DESCRIPTION=""

# Charge et parse un fichier stack YAML
# $1 = nom de la stack (sans .yaml)
# Effet : exporte les variables env globales et stocke la liste des layers
config_load_stack() {
  _config_check_yq

  local stack_name="$1"
  local stack_file="${ANISSA_STACKS}/${stack_name}.yaml"

  if [[ ! -f "$stack_file" ]]; then
    log_fatal "Stack '${stack_name}' introuvable : ${stack_file}"
  fi

  _STACK_NAME="$stack_name"
  _STACK_LAYERS_PATH=()
  _STACK_LAYERS_PLAN=()
  _STACK_LAYERS_ENV=()

  log_debug "Chargement de la stack: ${stack_file}"

  # Lire la description
  _STACK_DESCRIPTION=$(yq '.stack.description // ""' "$stack_file")

  # Exporter les variables env globales de la stack
  local global_env
  global_env=$(yq '.stack.env // {} | to_entries | .[] | .key + "=" + .value' "$stack_file" 2>/dev/null || true)

  if [[ -n "$global_env" ]]; then
    log_debug "Variables globales de la stack:"
    while IFS= read -r line; do
      log_debug "  export ${line}"
      export "${line?}"
    done <<< "$global_env"
  fi

  # Parser les layers
  local layer_count
  layer_count=$(yq '.stack.layers | length' "$stack_file")

  for ((i = 0; i < layer_count; i++)); do
    local layer_path plan layer_env

    layer_path=$(yq ".stack.layers[$i].layer" "$stack_file")
    plan=$(yq ".stack.layers[$i].plan" "$stack_file")

    # Collecter les env de cette layer comme un bloc
    layer_env=$(yq ".stack.layers[$i].env // {} | to_entries | .[] | .key + \"=\" + .value" "$stack_file" 2>/dev/null || true)

    _STACK_LAYERS_PATH+=("$layer_path")
    _STACK_LAYERS_PLAN+=("$plan")
    _STACK_LAYERS_ENV+=("$layer_env")
    log_debug "Layer [$i]: path=${layer_path} plan=${plan}"
  done
}

# Retourne le nombre de layers dans la stack chargée
config_get_layer_count() {
  echo "${#_STACK_LAYERS_PATH[@]}"
}

# Retourne le chemin layer à l'index donné
# $1 = index (0-based)
config_get_layer_path() {
  echo "${_STACK_LAYERS_PATH[$1]}"
}

# Retourne le plan à l'index donné
# $1 = index (0-based)
config_get_layer_plan() {
  echo "${_STACK_LAYERS_PLAN[$1]}"
}

# Retourne la référence "layer-path/plan" lisible
# $1 = index (0-based)
config_get_layer_ref() {
  local layer_path="${_STACK_LAYERS_PATH[$1]}"
  local plan="${_STACK_LAYERS_PLAN[$1]}"

  # Extraire le nom court de la layer (dernier segment du path)
  local layer_name
  layer_name=$(basename "$layer_path")

  echo "${layer_name}/${plan}"
}

# Exporte les variables env spécifiques à une layer
# $1 = index (0-based)
config_export_layer_env() {
  local idx="$1"
  local layer_env="${_STACK_LAYERS_ENV[$idx]}"

  if [[ -n "$layer_env" ]]; then
    log_debug "Variables env de la layer [$idx]:"
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      log_debug "  export ${line}"
      export "${line?}"
    done <<< "$layer_env"
  fi

  # Charger defaults.env si présent dans le dossier du plan
  local plan_dir
  plan_dir="${ANISSA_ROOT}/${_STACK_LAYERS_PATH[$idx]}/${_STACK_LAYERS_PLAN[$idx]}"

  if [[ -f "${plan_dir}/defaults.env" ]]; then
    log_debug "Chargement de defaults.env depuis ${plan_dir}"
    set -a
    # shellcheck source=/dev/null
    source "${plan_dir}/defaults.env"
    set +a
  fi
}

# Remplit un tableau avec les refs "layer-path/plan" du stack courant
# $1 = nom du tableau (par référence)
config_get_layers() {
  local -n _arr="$1"
  _arr=()

  local count=${#_STACK_LAYERS_PATH[@]}
  for ((i = 0; i < count; i++)); do
    _arr+=("$(config_get_layer_ref "$i")")
  done
}

# Retourne le nom de la stack chargée
config_get_stack_name() {
  echo "$_STACK_NAME"
}

# Retourne la description de la stack
config_get_stack_description() {
  echo "$_STACK_DESCRIPTION"
}
