# llm-command-in-container

Workspace conteneurisé embarquant la CLI [llm](https://llm.datasette.io/en/stable/) de Simon Willison, pré-configurée pour dialoguer avec le proxy LiteLLM (`kanissa-litellm`).

## Modèles disponibles

| Alias dans llm    | Modèle réel (via LiteLLM)         |
| ------------------ | --------------------------------- |
| `claude-sonnet`    | `claude-sonnet-4-20250514` (Vertex AI) |
| `local/llama3`     | `ollama/llama3` (Ollama local)    |

Le modèle par défaut est `claude-sonnet` (configurable via `LLM_DEFAULT_MODEL`).

## Utilisation

```bash
# Démarrer le conteneur
make up

# Lancer une requête llm
make llm           # mode interactif
./verbs/llm.sh "Explique le théorème de Bayes"
./verbs/llm.sh -m local/llama3 "Bonjour"

# Shell interactif dans le conteneur
make shell

# Voir les modèles disponibles
./verbs/llm.sh models

# Arrêter
make down
```

## Référence

- https://llm.datasette.io/en/stable/
- https://llm.datasette.io/en/stable/other-models.html#openai-compatible-models