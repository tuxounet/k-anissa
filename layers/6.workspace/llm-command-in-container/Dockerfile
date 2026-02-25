FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Dépendances système ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
      curl \
      git \
      ca-certificates \
      jq \
      python3 \
      python3-pip \
      python3-venv \
      pipx \
    && rm -rf /var/lib/apt/lists/*

# ── LLM CLI (datasette) ─────────────────────────────────────────────────────
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx install llm

# ── Configuration LLM : répertoire et modèles extra OpenAI-compatible ───────
ENV LLM_USER_PATH=/root/.config/io.datasette.llm
RUN mkdir -p ${LLM_USER_PATH}

COPY extra-openai-models.yaml ${LLM_USER_PATH}/extra-openai-models.yaml

# ── Répertoire de travail ────────────────────────────────────────────────────
RUN mkdir -p /workspace
WORKDIR /workspace

# ── Entrypoint ───────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]