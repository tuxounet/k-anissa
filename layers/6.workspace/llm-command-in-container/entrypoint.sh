#!/usr/bin/env bash
set -euo pipefail

# ── Definir le modele par defaut ────────────────────────────────────────────
if [ -n "${LLM_DEFAULT_MODEL:-}" ]; then
  llm models default "${LLM_DEFAULT_MODEL}" || echo "Warning: could not set default model '${LLM_DEFAULT_MODEL}', continuing anyway"
fi

# ── Enregistrer le template par défaut avec system prompt ───────────────────
SYSTEM_PROMPT_FILE="/etc/llm/default-system-prompt.txt"
TEMPLATE_DIR="${LLM_USER_PATH:-/root/.config/io.datasette.llm}/templates"
if [ -f "$SYSTEM_PROMPT_FILE" ]; then
  mkdir -p "$TEMPLATE_DIR"
  # llm templates are YAML files: { system: "..." }
  python3 -c "
import yaml, sys
prompt = open('$SYSTEM_PROMPT_FILE').read()
with open('$TEMPLATE_DIR/anissa.yaml', 'w') as f:
    yaml.dump({'system': prompt}, f, default_flow_style=False, allow_unicode=True)
" 2>/dev/null || {
    # Fallback without pyyaml: write manually
    echo "system: |" > "$TEMPLATE_DIR/anissa.yaml"
    sed 's/^/  /' "$SYSTEM_PROMPT_FILE" >> "$TEMPLATE_DIR/anissa.yaml"
  }
  echo "[llm] Default system prompt registered as template 'anissa'"
fi

# ── Configurer les serveurs MCP ─────────────────────────────────────────────
# Chaque serveur est activé par une variable d'environnement MCP_<NAME>=true
# llm mcp servers add "<cmd_string>" --name <name> contacts the server to
# discover its tools, then persists a JSON manifest.
# NOTE: MCP SDK only inherits HOME/PATH/SHELL/TERM/USER/LOGNAME by default,
# so any extra env vars (tokens, URLs) MUST be part of the command string.

add_mcp_server() {
  local name="$1" cmd_string="$2"
  echo "[mcp] Registering ${name} …"
  if llm mcp servers add "${cmd_string}" --name "${name}" --overwrite 2>&1; then
    echo "[mcp] ✔ ${name} registered"
  else
    echo "[mcp] ⚠ ${name} – tool discovery failed (server may be unreachable)"
  fi
}

# ── Prepare un repo git temporaire pour la decouverte des outils git ────────
GIT_DISCOVERY_REPO="/tmp/.mcp-git-discovery"
prepare_git_repo() {
  if [ ! -d "$GIT_DISCOVERY_REPO/.git" ]; then
    git init -q "$GIT_DISCOVERY_REPO"
  fi
}

# GitLab MCP Server  (@modelcontextprotocol/server-gitlab)
if [ "${MCP_GITLAB:-false}" = "true" ]; then
  add_mcp_server "gitlab" \
    "GITLAB_PERSONAL_ACCESS_TOKEN=${MCP_GITLAB_TOKEN:-unset} GITLAB_API_URL=${MCP_GITLAB_URL:-https://gitlab.com}/api/v4 npx -y @modelcontextprotocol/server-gitlab"
fi

# Kubernetes MCP Server  (kubernetes-mcp-server)
if [ "${MCP_KUBERNETES:-false}" = "true" ]; then
  add_mcp_server "kubernetes" "npx -y kubernetes-mcp-server"
fi

# Terraform MCP Server  (terraform-mcp-server)
if [ "${MCP_TERRAFORM:-false}" = "true" ]; then
  add_mcp_server "terraform" "npx -y terraform-mcp-server"
fi

# GCP MCP Server  (gcp-mcp)
if [ "${MCP_GCP:-false}" = "true" ]; then
  add_mcp_server "gcp" "npx -y gcp-mcp"
fi

# Git MCP Server  (mcp-server-git – Python, installed via pip)
if [ "${MCP_GIT:-false}" = "true" ]; then
  prepare_git_repo
  # Discover tools against the temp repo, then patch stored config to use real path
  GIT_REAL_REPO="${MCP_GIT_REPO:-/workspace}"
  if llm mcp servers add "mcp-server-git --repository ${GIT_DISCOVERY_REPO}" \
       --name git --overwrite 2>&1; then
    # Replace discovery repo with real path in stored JSON
    python3 -c "
import json, pathlib
p = pathlib.Path('${LLM_USER_PATH:-/root/.config/io.datasette.llm}/mcp/servers/git.json')
cfg = json.loads(p.read_text())
cfg['parameters']['args'] = ['--repository', '${GIT_REAL_REPO}']
p.write_text(json.dumps(cfg, indent=2))
"
    echo "[mcp] ✔ git registered (repo: ${GIT_REAL_REPO})"
  else
    echo "[mcp] ⚠ git – tool discovery failed"
  fi
fi

# Gitea MCP Server  (gitea-mcp-tool)
# NOTE: gitea-mcp-tool logs to stdout which breaks the MCP stdio protocol.
# @boringstudio_org/gitea-mcp doesn't implement MCP stdio at all.
# Both are currently non-functional; kept here for when a working package appears.
if [ "${MCP_GITEA:-false}" = "true" ]; then
  add_mcp_server "gitea" \
    "NODE_TLS_REJECT_UNAUTHORIZED=0 GITEA_BASE_URL=${MCP_GITEA_URL:-http://localhost:3000} GITEA_TOKEN=${MCP_GITEA_TOKEN:-unset} npx -y -p gitea-mcp-tool gitea-mcp"
fi

echo "[mcp] Configured servers:"
llm mcp servers list 2>/dev/null || true

# ── Garder le conteneur actif ───────────────────────────────────────────────
exec sleep infinity
