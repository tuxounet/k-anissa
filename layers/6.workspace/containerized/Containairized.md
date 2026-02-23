# Containairized

Start in a shell a Claude Code AI Agent interaction with MCP, Tools and LLM Proxy Backed.

## Description

This layer provides a containerized workspace running **Claude Code** — Anthropic's AI coding agent CLI — inside an isolated Docker container. It connects to the rest of the K-anIssA stack (LLM proxy, MCP servers, tools) via the shared `kanissa` network.

## What's included

| Component                  | Details                                                       |
| -------------------------- | ------------------------------------------------------------- |
| **Ubuntu 24.04**           | Base OS                                                       |
| **Node.js 20 LTS**        | Runtime for Claude Code and MCP servers                       |
| **Claude Code CLI**        | `@anthropic-ai/claude-code` — Interactive AI coding agent     |
| **MCP Servers (built-in)** | Gitlab, Terraform, AWS — activated via environment variables   |
| **LLM Proxy integration**  | Routes requests through LiteLLM (`kanissa-litellm`) on the network |

## Architecture

```
┌─────────────────────────────────────────────────┐
│              kanissa-workspace                  │
│  ┌───────────┐  ┌──────────────────────────┐    │
│  │ Claude    │──│ MCP Servers (stdio)      │    │
│  │ Code CLI  │  │  • gitlab                │    │
│  │           │  │  • terraform             │    │
│  └─────┬─────┘  │  • aws                   │    │
│        │        └──────────────────────────┘    │
└────────┼────────────────────────────────────────┘
         │ kanissa network
    ┌────┴──────────────────────┐
    │                           │
┌───▼──────────┐  ┌─────────────▼──┐
│ kanissa-     │  │ kanissa-tool-  │
│ litellm      │  │ heure          │
│ (LLM Proxy)  │  │ (Tools)        │
└──────────────┘  └────────────────┘
```

## Environment variables

| Variable                  | Description                      | Default                          |
| ------------------------- | -------------------------------- | -------------------------------- |
| `ANTHROPIC_API_KEY`       | Anthropic API key for Claude Code | *(required)*                    |
| `ANTHROPIC_BASE_URL`      | Custom API base URL (e.g. LiteLLM proxy) | Anthropic default        |
| `GITLAB_TOKEN`            | Gitlab personal access token     | *(disabled if empty)*            |
| `GITLAB_API_URL`          | Gitlab API URL                   | `https://gitlab.com/api/v4`     |
| `TERRAFORM_TOKEN`         | Terraform Cloud token            | *(disabled if empty)*            |
| `AWS_ACCESS_KEY_ID`       | AWS access key                   | *(disabled if empty)*            |
| `AWS_SECRET_ACCESS_KEY`   | AWS secret key                   | *(disabled if empty)*            |
| `AWS_REGION`              | AWS region                       | `eu-west-1`                      |

## Usage

Once the stack is up, launch Claude Code:

```bash
docker exec -it kanissa-workspace claude
```

Or open a shell in the workspace:

```bash
docker exec -it kanissa-workspace bash
```

## Data persistence

| Path in container       | Host mount                                |
| ----------------------- | ----------------------------------------- |
| `/workspace`            | `${KANISSA_DATA}/workspace`               |
| `/root/.claude`         | `${KANISSA_DATA}/claude-code`             | 