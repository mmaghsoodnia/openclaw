# OpenClaw Staging — op inject template
# Secrets are resolved by `op inject`. Paths are appended by start.sh.

OPENCLAW_GATEWAY_TOKEN={{ op://OpenClaw/Staging Gateway Token/credential }}
GOG_KEYRING_PASSWORD={{ op://OpenClaw/GOG Keyring Password/password }}

# --- LLM Provider API Keys (env fallback for all agents) ---
OPENAI_API_KEY={{ op://OpenClaw/OpenAI API Key/credential }}
XAI_API_KEY={{ op://OpenClaw/XAI API key/credential }}
GEMINI_API_KEY={{ op://OpenClaw/Google Gemini API Key/credential }}
ANTHROPIC_API_KEY={{ op://OpenClaw/Anthropic API Key/credential }}
MAPLE_API_KEY={{ op://OpenClaw/Maple API Key/credential }}
VENICE_API_KEY={{ op://OpenClaw/Venice API Key/credential }}
DEEPSEEK_API_KEY={{ op://OpenClaw/DeepSeek API Key/credential }}
GROQ_API_KEY={{ op://OpenClaw/Groq API Key/credential }}
BRAVE_API_KEY={{ op://OpenClaw/Brave API Key/credential }}
ELEVENLABS_API_KEY={{ op://OpenClaw/ElevenLabs Talk API Key/credential }}
