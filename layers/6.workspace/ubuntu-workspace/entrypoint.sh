#!/usr/bin/env bash
set -euo pipefail
#=============================================================================
# Entrypoint — Workspace Conteneurisé
#=============================================================================

chown -R ${USERNAME}:${USERNAME} /workspace

# ── Démarrage du serveur SSH ──────────────────────────────────────────────────
echo "[kanissa] Démarrage du serveur SSH sur le port 2222..."
/usr/sbin/sshd

echo "[kanissa] Workspace conteneurisé prêt."

# Maintenir le conteneur en vie
exec sleep infinity
