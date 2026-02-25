# K-anIssA

> Or, how to host a bot?

Solution modulaire multi-couches pour héberger un assistant IA complet : modèles locaux, proxy LLM, outils MCP, workspace et interfaces utilisateur — le tout orchestré depuis un simple script shell.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  10. Clients      │ Open WebUI │ Wetty │ VSCodium           │
├─────────────────────────────────────────────────────────────┤
│  6.  Workspace    │ Conteneurisé │ Dossier courant         │
├─────────────────────────────────────────────────────────────┤
│  5.  MCP          │ AWS │ Gitlab │ Kubernetes │ Terraform   │
├─────────────────────────────────────────────────────────────┤
│  4.  Tools        │ heure │ ...                             │
├─────────────────────────────────────────────────────────────┤
│  3.  Proxy        │ LiteLLM (OpenAI-compatible)             │
├─────────────────────────────────────────────────────────────┤
│  2.  Local Subs   │ Ollama embedded │ Ollama registry       │
├─────────────────────────────────────────────────────────────┤
│  1.  Cloud Subs   │ Azure Vertex AI │ GCP Vertex AI        │
└─────────────────────────────────────────────────────────────┘
         ▲
         │  Réseau Docker partagé : kanissa
```

Chaque couche est un composant Docker Compose autonome. Un profil (starter) définit quels composants activer.

## Prérequis

- Linux (Ubuntu 22.04+ recommandé)
- Docker Engine 24+ avec le plugin `docker compose`
- `curl` (pour les health-checks)
- `jq`, `yq` (installés via `make setup`)
- Go + `k2` (pour le rendering des templates, optionnel)

## Démarrage rapide

```bash
# Installer les dépendances (jq, yq, k2)
make setup

# Lister les stacks disponibles
make stacks
# ou : ./anissa/bin/anissa stacks

# Démarrer la stack (par défaut : lab)
make up
# ou : ./anissa/bin/anissa up lab

# Voir le statut
make status
# ou : ./anissa/bin/anissa status lab

# Consulter les logs
make logs
# ou : ./anissa/bin/anissa logs lab

# Lancer Claude Code dans le workspace conteneurisé
make claude
# ou : ./anissa/bin/anissa run lab custom-workspace-in-container claude

# Tout arrêter
make down
# ou : ./anissa/bin/anissa down lab
```

### Choisir une stack

La variable `STACK` permet de cibler une stack différente (par défaut `lab`) :

```bash
# Via Make
make up STACK=off-grid
make claude STACK=claude-code-proxy-vertex

# Via CLI
./anissa/bin/anissa up off-grid
./anissa/bin/anissa run off-grid custom-workspace-in-container claude
```

Stacks disponibles :

| Stack | Description |
|---|---|
| `lab` | Stack de développement et test (Ollama local + proxy + workspace) |
| `off-grid` | Stack locale complète sans accès cloud |
| `claude-code-proxy-vertex` | Proxy vers Vertex AI (Claude via GCP) |

### Mode debug

```bash
make up DEBUG=1
# ou : ./anissa/bin/anissa --debug up lab
```

## Utilisation de Claude Code

Le verbe `claude` lance une session interactive Claude Code dans le conteneur workspace.

```bash
# Via Makefile (stack par défaut : lab)
make claude

# Via Makefile avec une stack spécifique
make claude STACK=claude-code-proxy-vertex

# Via CLI directement
./anissa/bin/anissa run <stack> custom-workspace-in-container claude
```

### Autres verbes du workspace

Chaque layer peut exposer des verbes personnalisés dans son dossier `verbs/`. Pour le workspace conteneurisé :

```bash
# Lister les verbes disponibles
./anissa/bin/anissa run lab custom-workspace-in-container
# ou : make run LAYER=custom-workspace-in-container

# Exécuter un verbe spécifique
make run LAYER=custom-workspace-in-container VERB=shell
# ou : ./anissa/bin/anissa run lab custom-workspace-in-container shell
```

| Verbe | Description |
|---|---|
| `claude` | Lance Claude Code dans le conteneur |
| `shell` | Ouvre un shell dans le conteneur workspace |
| `up` | Démarre le conteneur workspace |
| `down` | Arrête le conteneur workspace |
| `logs` | Affiche les logs du conteneur workspace |

## Structure du projet

```
anissa/
  bin/
    anissa                   # CLI principal
  lib/
    colors.sh                # Couleurs terminal
    logging.sh               # Fonctions de log
    docker.sh                # Helpers Docker
    layers.sh                # Gestion des couches & verbes
    config.sh                # Chargement des stacks
    progress.sh              # Affichage progression
layers/
  <N>.<catégorie>/
    <composant>/
      compose.yml            # Définition Docker Compose
      layer.sh               # Hooks optionnels (pre/post start/stop)
      .env                   # Variables optionnelles
      verbs/                 # Scripts de verbes exécutables
        <verb>.sh
stacks/
  <stack>.yaml               # Définition des layers et variables
```

## Commandes

### Via Makefile

| Commande | Description |
|---|---|
| `make up` | Démarre la stack (défaut: `lab`) |
| `make down` | Arrête la stack |
| `make restart` | Redémarre la stack |
| `make status` | Affiche le statut de chaque layer |
| `make logs` | Affiche les logs |
| `make healthcheck` | Vérifie la santé des services |
| `make shell` | Ouvre un shell dans le premier layer |
| `make claude` | Lance Claude Code dans le workspace |
| `make stacks` | Liste les stacks disponibles |
| `make layers` | Liste toutes les couches/composants |
| `make run LAYER=<l> VERB=<v>` | Exécute un verbe sur un layer |
| `make setup` | Installe les dépendances (jq, yq, k2) |
| `make render` | Rend les templates via k2 |

### Via CLI

| Commande | Description |
|---|---|
| `anissa up <stack>` | Démarre tous les layers de la stack |
| `anissa down <stack>` | Arrête tous les layers (ordre inverse) |
| `anissa restart <stack>` | Redémarre la stack |
| `anissa status <stack>` | Affiche le statut de chaque layer |
| `anissa logs <stack>` | Affiche les logs |
| `anissa healthcheck <stack>` | Vérifie la santé des services |
| `anissa shell <stack> [layer]` | Ouvre un shell dans un layer |
| `anissa run <stack> <layer> [verb] [args]` | Exécute un verbe sur un layer |
| `anissa stacks` | Liste les stacks disponibles |
| `anissa layers` | Liste toutes les couches/composants |

## Licence

Voir [LICENSE](LICENSE).

