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

# ── Node.js (pour les serveurs MCP via npx) ─────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── LLM CLI (datasette) + plugin MCP ────────────────────────────────────────
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx install llm \
    && pipx inject llm llm-mcp

# ── Serveur MCP Git (Python) ────────────────────────────────────────────────
RUN pip install --break-system-packages mcp-server-git

# ── Configuration LLM : répertoire et modèles extra OpenAI-compatible ───────
ENV LLM_USER_PATH=/root/.config/io.datasette.llm
RUN mkdir -p ${LLM_USER_PATH}

COPY extra-openai-models.yaml ${LLM_USER_PATH}/extra-openai-models.yaml

# ── System prompt par défaut ─────────────────────────────────────────────────
COPY default-system-prompt.txt /etc/llm/default-system-prompt.txt

# ── Répertoire de travail ────────────────────────────────────────────────────
RUN mkdir -p /workspace
WORKDIR /workspace

# ── Entrypoint ───────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]