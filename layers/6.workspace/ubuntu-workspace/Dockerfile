FROM ubuntu:24.04

ARG USERNAME=user

ENV DEBIAN_FRONTEND=noninteractive
ENV USERNAME=${USERNAME}

# ── Dépendances système ──────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
      curl \
      git \
      ca-certificates \
      gnupg \
      jq \
      nano \
      htop \
      bmon \
      python3 \
      python3-pip \
      python3-venv \
      openssh-client \
      openssh-server \
      wget \
      unzip \
    && rm -rf /var/lib/apt/lists/*

# ── Utilisateur non-root (renomme ubuntu:1000 au lieu d'en créer un) ─────────
RUN usermod -l "${USERNAME}" -d /home/${USERNAME} -m ubuntu \
    && groupmod -n "${USERNAME}" ubuntu

# ── Configuration SSH (clé uniquement) ───────────────────────────────────────
RUN mkdir -p /run/sshd /home/${USERNAME}/.ssh \
    && chmod 700 /home/${USERNAME}/.ssh \
    && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh \
    && sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config \
    && echo "AuthorizedKeysFile /etc/kanissa-ssh/id_ed25519.pub" >> /etc/ssh/sshd_config

EXPOSE 2222

# ── Node.js 22 LTS ──────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
RUN mkdir -p /workspace

# ── Prompt Bash avec Git ─────────────────────────────────────────────────────
RUN cat >> /home/${USERNAME}/.bashrc <<'BASHRC'

# ── Git-enhanced prompt ──────────────────────────────────────────────────────
__git_prompt() {
  local branch dirty stash
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || return
  dirty=""
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    dirty="*"
  fi
  if [[ -n $(git stash list 2>/dev/null) ]]; then
    stash=" \[\e[33m\]⚑"
  else
    stash=""
  fi
  printf " \[\e[36m\](%s%s%s\[\e[36m\])" "$branch" "\[\e[31m\]$dirty" "$stash"
}

PS1='\[\e[1;32m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\]:\[\e[1;33m\]\w\[\e[0m\]$(__git_prompt)\[\e[0m\]\$ '
BASHRC


COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
