#!/usr/bin/env bash
set -euo pipefail

# ── Definir le modele par defaut ────────────────────────────────────────────
if [ -n "${LLM_DEFAULT_MODEL:-}" ]; then
  llm models default "${LLM_DEFAULT_MODEL}"
fi

# ── Garder le conteneur actif ───────────────────────────────────────────────
exec sleep infinity
