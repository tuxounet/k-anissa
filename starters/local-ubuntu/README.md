# Guide de démarrage pour une machine locale sous Ubuntu

## Composants activés

| Couche | Composant | Port | Description |
|---|---|---|---|
| 2. Local Subs | Ollama embedded | 11434 | Modèles LLM locaux |
| 3. Proxy | LiteLLM | 4000 | Routeur multi-modèle OpenAI-compatible |
| 4. Tools | heure | 9100 | Micro-service exemple |
| 6. Workspace | current-folder | — | Monte `~/workspace` |
| 10. Clients | Open WebUI | 8080 | Interface web pour chat LLM |
| 10. Clients | Wetty | 3000 | Terminal web SSH |
| 10. Clients | VSCodium | 8443 | IDE web |

## Prérequis

- Ubuntu 22.04+
- Docker Engine 24+ avec `docker compose`
- Au moins 8 Go de RAM (16 Go recommandé pour les modèles locaux)

## Installation

```bash
# Depuis la racine du projet
chmod +x bin/kanissa

# Créer le dossier workspace
mkdir -p ~/workspace

# Démarrer
bin/kanissa up local-ubuntu
```

## Accès aux services

- **Open WebUI** : http://localhost:8080
- **Wetty (terminal)** : http://localhost:3000
- **Code Server (IDE)** : http://localhost:8443
- **Ollama API** : http://localhost:11434
- **LiteLLM API** : http://localhost:4000

## Personnalisation

Modifier `profile.env` pour :
- Changer les ports
- Ajouter/retirer des composants
- Configurer les modèles Ollama à télécharger
- Ajuster les variables d'environnement

