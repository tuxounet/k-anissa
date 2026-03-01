# Recettes

Catalogue de recettes (templates) disponibles pour construire des layers.

## docker-compose

Lance un service via `docker compose`. Le layer fournit le contenu du fichier `compose.yml`.

| Paramètre     | Description                          |
| ------------- | ------------------------------------ |
| `name`        | Nom du projet docker-compose         |
| `title`       | Titre affiché                        |
| `description` | Description du composant             |
| `accessUrl`   | URL d'accès (optionnel)              |
| `composeFile` | Contenu du fichier `compose.yml`     |

**Verbes :** `up`, `down`, `logs`, `shell`, `url`

---

## shell-script

Exécute un script shell arbitraire au `up` et/ou au `down`.

| Paramètre    | Description                            |
| ------------ | -------------------------------------- |
| `name`       | Nom du composant                       |
| `title`      | Titre affiché                          |
| `description`| Description                            |
| `accessUrl`  | URL d'accès (optionnel)                |
| `upScript`   | Script bash exécuté au `up`            |
| `downScript` | Script bash exécuté au `down`          |

**Verbes :** `up`, `down`, `url`

---

## ansible-playbook

Lance un playbook Ansible au `up` et au `down`. Le layer fournit le contenu des playbooks et de l'inventaire.

| Paramètre          | Description                                        |
| ------------------- | -------------------------------------------------- |
| `name`             | Nom du composant                                    |
| `title`            | Titre affiché                                       |
| `description`      | Description                                         |
| `accessUrl`        | URL d'accès (optionnel)                             |
| `inventoryContent` | Contenu du fichier d'inventaire Ansible (`ini`)     |
| `playbookUp`       | Contenu du playbook exécuté au `up`                 |
| `playbookDown`     | Contenu du playbook exécuté au `down`               |
| `extraVars`        | Variables supplémentaires passées via `--extra-vars` (optionnel) |

**Verbes :** `up`, `down`, `check` (dry-run), `url`

### Exemple d'utilisation dans un layer

```yaml
k2:
  metadata:
    id: k.apps.anissa.layers.example.ansible-demo
    kind: template-apply
  body:
    template:
      source: inventory
      params:
        id: k.anissa.recettes.ansible-playbook
    vars:
      name: ansible-demo
      title: Ansible Demo
      description: Exemple de provisioning via Ansible
      inventoryContent: |
        [local]
        localhost ansible_connection=local
      playbookUp: |
        ---
        - name: Ansible Demo — up
          hosts: all
          gather_facts: false
          tasks:
            - name: Créer un répertoire de travail
              ansible.builtin.file:
                path: /tmp/ansible-demo
                state: directory
      playbookDown: |
        ---
        - name: Ansible Demo — down
          hosts: all
          gather_facts: false
          tasks:
            - name: Supprimer le répertoire de travail
              ansible.builtin.file:
                path: /tmp/ansible-demo
                state: absent
```
