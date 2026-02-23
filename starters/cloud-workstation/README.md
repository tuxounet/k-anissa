# Démarrage depuis une Google Cloud Workstation

## Composants activés

| Couche | Composant | Port | Description |
|---|---|---|---|
| 2. Local Subs | Ollama embedded | 11434 | Modèles LLM locaux |
| 3. Proxy | LiteLLM | 4000 | Routeur multi-modèle |
| 4. Tools | heure | 9100 | Micro-service exemple |
| 6. Workspace | containerized | — | Workspace Docker isolé |
| 10. Clients | Open WebUI | 8080 | Interface web (auth activée) |

## Prérequis

- Google Cloud Workstation avec Docker
- GPU optionnel mais recommandé

## Installation

```bash
chmod +x bin/kanissa
bin/kanissa up cloud-workstation
```

## Personnalisation

Pour activer les providers cloud, décommenter et remplir les variables dans `profile.env` :
- `AZURE_API_KEY` / `AZURE_API_BASE` pour Azure
- `GCP_PROJECT_ID` / `GCP_LOCATION` pour Vertex AI
