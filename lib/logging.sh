#!/usr/bin/env bash
#=============================================================================
# Fonctions de logging
#=============================================================================

log_info() {
  printf "${BLUE}[info]${RESET}  %b\n" "$*"
}

log_success() {
  printf "${GREEN}[ok]${RESET}    %b\n" "$*"
}

log_warn() {
  printf "${YELLOW}[warn]${RESET}  %b\n" "$*"
}

log_error() {
  printf "${RED}[err]${RESET}   %b\n" "$*" >&2
}

log_step() {
  printf "${CYAN}  ➜${RESET}  %b\n" "$*"
}

log_debug() {
  [[ "${KANISSA_DEBUG:-0}" == "1" ]] && printf "${DIM}[debug] %b${RESET}\n" "$*"
}
