FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Dépendances système ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
      curl \
      git \
      ca-certificates \
      gnupg \
      jq \
      python3 \
      python3-pip \
      openssh-client \
      openssh-server \
      wget \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Configuration SSH (clé uniquement) ───────────────────────────────────────
RUN mkdir -p /run/sshd /root/.ssh \
    && chmod 700 /root/.ssh \
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22

# ── Node.js 20 LTS ──────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── Claude Code CLI ─────────────────────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── Pré-installation des serveurs MCP (évite les téléchargements au runtime)─
RUN npm install -g \
      @modelcontextprotocol/server-gitlab

# ── Répertoires de travail ───────────────────────────────────────────────────
RUN mkdir -p /workspace /root/.claude

WORKDIR /workspace

# ── Entrypoint ───────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
