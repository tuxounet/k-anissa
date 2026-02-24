#!/usr/bin/env bash
set -euo pipefail
#=============================================================================
# Entrypoint — Workspace conteneurisé Claude Code
#
# Génère la configuration Claude Code (settings.json) à partir des variables
# d'environnement, puis maintient le conteneur en vie.
#=============================================================================

CLAUDE_DIR="/root/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

mkdir -p "$CLAUDE_DIR"

#--- Construction dynamique du settings.json --------------------------------
# On construit les serveurs MCP uniquement si les tokens/configs sont présents

MCP_SERVERS="{"

# Gitlab MCP
if [[ -n "${GITLAB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
  MCP_SERVERS+="$(cat <<'MCPEOF'
    "gitlab": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-gitlab"],
      "env": {
        "GITLAB_PERSONAL_ACCESS_TOKEN": "__GITLAB_TOKEN__",
        "GITLAB_API_URL": "__GITLAB_API_URL__"
      }
    },
MCPEOF
)"
  MCP_SERVERS="${MCP_SERVERS//__GITLAB_TOKEN__/$GITLAB_PERSONAL_ACCESS_TOKEN}"
  MCP_SERVERS="${MCP_SERVERS//__GITLAB_API_URL__/${GITLAB_API_URL:-https://gitlab.com/api/v4}}"
fi

# Terraform MCP
if [[ -n "${TF_TOKEN:-}" ]]; then
  MCP_SERVERS+="$(cat <<'MCPEOF'
    "terraform": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-terraform"],
      "env": {
        "TF_TOKEN": "__TF_TOKEN__"
      }
    },
MCPEOF
)"
  MCP_SERVERS="${MCP_SERVERS//__TF_TOKEN__/$TF_TOKEN}"
fi

# AWS MCP
if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
  MCP_SERVERS+="$(cat <<'MCPEOF'
    "aws": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-aws"],
      "env": {
        "AWS_ACCESS_KEY_ID": "__AWS_KEY__",
        "AWS_SECRET_ACCESS_KEY": "__AWS_SECRET__",
        "AWS_REGION": "__AWS_REGION__"
      }
    },
MCPEOF
)"
  MCP_SERVERS="${MCP_SERVERS//__AWS_KEY__/$AWS_ACCESS_KEY_ID}"
  MCP_SERVERS="${MCP_SERVERS//__AWS_SECRET__/${AWS_SECRET_ACCESS_KEY:-}}"
  MCP_SERVERS="${MCP_SERVERS//__AWS_REGION__/${AWS_REGION:-eu-west-1}}"
fi

# Retirer la virgule finale éventuelle et fermer l'objet
MCP_SERVERS="$(echo "$MCP_SERVERS" | sed 's/,$//')"
MCP_SERVERS+="}"

#--- Écriture du fichier settings.json -------------------------------------
cat > "$SETTINGS_FILE" <<EOF
{
  "permissions": {
    "allow": [],
    "deny": []
  },
  "mcpServers": $MCP_SERVERS
}
EOF

# Valider que le JSON est correct
if command -v jq &>/dev/null; then
  if ! jq . "$SETTINGS_FILE" > /dev/null 2>&1; then
    echo "[kanissa] WARN: settings.json invalide, utilisation d'une config minimale"
    cat > "$SETTINGS_FILE" <<'EOF'
{
  "permissions": { "allow": [], "deny": [] },
  "mcpServers": {}
}
EOF
  fi
fi

echo "[kanissa] Claude Code settings générés dans $SETTINGS_FILE"
echo "[kanissa] Serveurs MCP configurés :"
jq -r '.mcpServers | keys[]' "$SETTINGS_FILE" 2>/dev/null | while read -r srv; do
  echo "  - $srv"
done

# ── Configuration de la clé SSH autorisée ─────────────────────────────────────
mkdir -p /root/.ssh
if [[ -f /etc/kanissa-ssh/id_ed25519.pub ]]; then
  cp /etc/kanissa-ssh/id_ed25519.pub /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo "[kanissa] Clé SSH autorisée installée"
else
  echo "[kanissa] WARN: Clé publique SSH introuvable dans /etc/kanissa-ssh/"
fi

# ── Démarrage du serveur SSH ──────────────────────────────────────────────────
echo "[kanissa] Démarrage du serveur SSH..."
/usr/sbin/sshd

echo "[kanissa] Workspace conteneurisé prêt."
echo "[kanissa] Utiliser : docker exec -it kanissa-workspace claude"

# Maintenir le conteneur en vie
exec sleep infinity
