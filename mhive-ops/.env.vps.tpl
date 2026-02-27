# OpenClaw VPS — op inject template
# Secrets are resolved by `op inject` using the service account token.
# Usage: OP_SERVICE_ACCOUNT_TOKEN=$(<~/.op-service-account-token) op inject -i mhive-ops/.env.vps.tpl -o .env

# --- Gateway ---
OPENCLAW_GATEWAY_TOKEN={{ op://OpenClaw/OpenClaw Gateway Token/credential }}

# --- Paths & Bind ---
OPENCLAW_CONFIG_DIR=/root/.openclaw
OPENCLAW_WORKSPACE_DIR=/root/.openclaw/workspace
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
OPENCLAW_IMAGE=openclaw:local

# --- LLM Provider API Keys (env fallback for all agents) ---
OPENAI_API_KEY={{ op://OpenClaw/OpenAI API Key/credential }}
XAI_API_KEY={{ op://OpenClaw/XAI API key/credential }}
GEMINI_API_KEY={{ op://OpenClaw/Google Gemini API Key/credential }}
ANTHROPIC_API_KEY={{ op://OpenClaw/Anthropic API Key/credential }}

# --- Tools ---
BRAVE_API_KEY={{ op://OpenClaw/Brave API Key/credential }}

# --- Google Workspace (gog) ---
GOG_KEYRING_PASSWORD={{ op://OpenClaw/GOG Keyring Password/password }}
GOG_ACCOUNT=mhive@bigbraincap.com
