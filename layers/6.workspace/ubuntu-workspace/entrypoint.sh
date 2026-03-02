#!/usr/bin/env bash
set -euo pipefail
#=============================================================================
# Entrypoint — Workspace Conteneurisé
#=============================================================================

chown -R ${USERNAME}:${USERNAME} /workspace

# ── Préparation du log tlog ────────────────────────────────────────────────────
mkdir -p /var/log/tlog
chown ${USERNAME}:${USERNAME} /var/log/tlog
touch /var/log/tlog/session.log
chown ${USERNAME}:${USERNAME} /var/log/tlog/session.log

# ── Préparation du runtime tlog (lock files + utmp) ──────────────────────────
mkdir -p /var/run/tlog
chown ${USERNAME}:${USERNAME} /var/run/tlog
touch /var/run/utmp
chmod 664 /var/run/utmp

# ── Démarrage du serveur SSH ──────────────────────────────────────────────────
echo "[kanissa] Démarrage du serveur SSH sur le port 2222..."
/usr/sbin/sshd

echo "[kanissa] Workspace conteneurisé prêt."

# ── Afficher les 30 dernières lignes du journal tlog ──────────────────────────
echo "[kanissa] Dernières sessions tlog :"
tail -n 30 /var/log/tlog/session.log 2>/dev/null || true

# ── Suivre l'activité utilisateur dans les logs du conteneur ──────────────────
exec tail -F /var/log/tlog/session.log
