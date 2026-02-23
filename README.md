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

## Démarrage rapide

```bash
# Rendre le CLI exécutable
chmod +x bin/kanissa

# Lister les profils disponibles
bin/kanissa profiles

# Démarrer le profil local Ubuntu
bin/kanissa up local-ubuntu

# Voir le statut
bin/kanissa status local-ubuntu

# Consulter les logs d'un composant
bin/kanissa logs local-ubuntu 2.locals-subscriptions/ollama-embedded

# Tout arrêter
bin/kanissa down local-ubuntu
```

## Structure du projet

```
bin/
  kanissa                    # CLI principal
lib/
  colors.sh                  # Couleurs terminal
  logging.sh                 # Fonctions de log
  docker.sh                  # Helpers Docker
  layers.sh                  # Gestion des couches
  config.sh                  # Chargement des profils
layers/
  <N>.<catégorie>/
    <composant>/
      compose.yml            # Définition Docker Compose
      layer.sh               # Hooks optionnels (pre/post start/stop)
      .env                   # Variables optionnelles
starters/
  <profil>/
    profile.env              # Composants activés + variables
    README.md                # Documentation du profil
```

## Commandes

| Commande | Description |
|---|---|
| `kanissa up <profil>` | Démarre tous les composants du profil |
| `kanissa down <profil>` | Arrête tous les composants (ordre inverse) |
| `kanissa restart <profil>` | Redémarre le profil |
| `kanissa status <profil>` | Affiche le statut de chaque composant |
| `kanissa logs <profil> [composant]` | Affiche les logs |
| `kanissa profiles` | Liste les profils disponibles |
| `kanissa layers` | Liste toutes les couches/composants |

## Créer un nouveau composant

1. Créer un dossier dans la couche appropriée : `layers/<N>.<catégorie>/<nom>/`
2. Ajouter un `compose.yml` avec le service Docker
3. Optionnel : ajouter un `layer.sh` avec les hooks `pre_start`, `post_start`, `pre_stop`, `post_stop`
4. Ajouter la référence dans le `profile.env` du starter souhaité

## Créer un nouveau profil

1. Créer un dossier dans `starters/<nom>/`
2. Créer un `profile.env` listant les composants à activer
3. Documenter dans un `README.md`

## Licence

Voir [LICENSE](LICENSE).

