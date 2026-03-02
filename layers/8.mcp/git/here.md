# mcp-git

Installe le serveur MCP Git ([`mcp-server-git`](https://github.com/modelcontextprotocol/servers/tree/main/src/git)) dans le workspace via SSH.

Ce serveur MCP expose des outils Git (status, diff, log, commit, etc.) aux clients MCP comme OpenCode ou Claude Code.

## What it does

- **up** : se connecte via SSH au workspace et installe `mcp-server-git` via pip
- **down** : se connecte via SSH et désinstalle le package

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `SSH_PORT` | `2222` | Port SSH du conteneur workspace |
| `SSH_USER` | `tuxounet` | Utilisateur SSH du conteneur workspace |

## Prerequisites

- Layer `6.workspace/workspace-keypair` doit être appliquée (clés SSH générées)
- Layer `6.workspace/ubuntu-workspace` doit être démarrée (conteneur workspace avec SSH et Node.js)
