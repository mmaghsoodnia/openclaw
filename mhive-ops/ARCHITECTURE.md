# OpenClaw System Architecture
## Operator's Mental Model for Safe, Coherent Project Management

> **Read this before touching anything.** This document captures how the gateway, agents,
> and context window actually work — so you know which layer you're operating in and what
> side-effects your changes will have on the live agent system.

---

## The Two-Layer Model

Everything in this project lives in one of two layers. Getting this wrong is the primary
source of coherence damage.

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 1 — OPERATOR / INFRASTRUCTURE                            │
│  Owner: us (Claude Code, VPS admin, Mac)                        │
│                                                                 │
│  • /root/openclaw/          ← gateway source code               │
│  • /root/openclaw/Dockerfile                                    │
│  • /root/openclaw/docker-compose*.yml                           │
│  • /root/.openclaw/openclaw.json   ← gateway config             │
│  • 1Password vault "OpenClaw"      ← secrets                    │
│  • Python venv / apt packages      ← system deps                │
│                                                                 │
│  Changes here: edit directly, no agent notification needed      │
│  EXCEPTION: if a change affects what an agent depends on        │
│  (e.g. venv path, env var name), send a notification via mhive  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  LAYER 2 — AGENT WORKSPACE (agents' "minds")                    │
│  Owner: the agents themselves                                   │
│                                                                 │
│  • /root/.openclaw/workspace/SOUL.md                            │
│  • /root/.openclaw/workspace/MEMORY.md                          │
│  • /root/.openclaw/workspace/USER.md                            │
│  • /root/.openclaw/workspace/AGENTS.md                          │
│  • /root/.openclaw/workspace/HEARTBEAT.md                       │
│  • /root/.openclaw/workspace/IDENTITY.md                        │
│  • /root/.openclaw/workspace/TOOLS.md                           │
│  • /root/.openclaw/workspace/{agent}/RUNBOOK.md                 │
│  • /root/.openclaw/workspace/{agent}/SOUL.md                    │
│  • /root/.openclaw/workspace/memory/YYYY-MM-DD.md  ← daily logs │
│                                                                 │
│  Changes here: NOTIFY agent first via mhive Telegram.           │
│  Direct edits are a last resort (agent offline/broken).         │
│  Silent edits here cause identity/memory incoherence.           │
└─────────────────────────────────────────────────────────────────┘
```

---

## How the Context Window Is Built

When any agent responds to a message, the gateway constructs a single API call to the
model. Understanding this determines how our changes propagate.

### Full context assembly order

```
SYSTEM PROMPT (one string, built by src/agents/system-prompt.ts)
│
├── [HARDCODED BY GATEWAY CODE — agent never sees the source files]
│   ├── ## Tooling          — all ~30 tool names + one-line descriptions
│   ├── ## Skills           — scan SKILL.md before replying
│   ├── ## Memory Recall    — use memory_search before answering history questions
│   ├── ## User Identity    — owner Telegram ID (217834570)
│   ├── ## Current Date & Time — timezone: America/Los_Angeles
│   ├── ## Workspace Files (injected) — header only, content follows below
│   ├── ## Reply Tags / Messaging / Voice / Heartbeats / Silent Replies
│   └── ## Runtime          — agentId, model, channel, OS, capabilities
│
└── [INJECTED FROM WORKSPACE FILES — user/operator editable]
    └── # Project Context
        ├── AGENTS.md        — loaded first, always
        ├── SOUL.md          ← persona & tone — model is told to EMBODY this
        ├── TOOLS.md
        ├── IDENTITY.md
        ├── USER.md
        ├── HEARTBEAT.md
        └── MEMORY.md        ← injected verbatim; up to 20k chars per file,
                               150k chars total budget across all files

MESSAGES ARRAY (conversation history, from session JSONL on disk)
│
├── { role: "user",      content: "..." }  ← historical turns
├── { role: "assistant", content: "..." }
├── { role: "tool",      content: "..." }  ← tool call results
├── ...
└── { role: "user",      content: "..." }  ← current message

TOOLS BLOCK (structured JSON schema, not plain text)
└── [~30 function definitions: read, write, edit, exec, message, sessions_send, ...]
```

### Key facts about the context window

1. **SOUL.md and MEMORY.md are part of the system prompt.** They are concatenated verbatim
   into the system prompt string before the API call. The model treats them with the same
   authority as hardcoded gateway instructions. An edit to either file takes effect on the
   very next message — no restart required.

2. **Subagent and cron sessions get a stripped context.** Session keys containing
   `_subagent_` or `_cron_` only receive `AGENTS.md` + `TOOLS.md` plus a minimal system
   prompt (no heartbeat, no messaging sections). This reduces token burn for background tasks.

3. **History is truncated, not infinite.** The gateway caps DM session history (typically
   50–100 turns). When context overflows the model's limit, the gateway auto-compacts by
   summarizing old messages. Agents don't see this happening.

4. **Tools are schema, not text.** The agent sees tool names and descriptions in
   `## Tooling` as text, and the actual callable schemas in the tools block. These are
   generated fresh every call — not stored in the session file.

5. **Secrets never appear in context.** API keys are injected via Docker environment
   variables from 1Password (see "Secrets Management" section). They are never part of
   the prompt or context window.

---

## The Rule: Which Layer Determines How We Change Things

| What you want to change | Layer | Correct approach |
|---|---|---|
| ElevenLabs API key | 1 — `openclaw.json` `talk.apiKey` | Edit directly via `op inject` or template |
| Google OAuth secret | 1 — `gog` config + 1Password | Rotate in Google Cloud, update 1Password, re-auth gog |
| Python packages in container | 1 — Dockerfile or startup script | Add to Dockerfile; send mhive notification about new venv path |
| Add WhatsApp channel | 1 — `openclaw.json` channels + auth | Trigger `whatsapp_login` agent tool via mhive Telegram message |
| Enable voice for an agent | 1 — `openclaw.json` `talk` config | Edit directly |
| New agent system prompt rules | 1 — gateway source (`system-prompt.ts`) | Code change → build → deploy |
| Agent's personality or mission | 2 — `SOUL.md` | Send mhive a message explaining the change; let the agent update its own SOUL.md |
| Agent's long-term memory | 2 — `MEMORY.md` | Message the agent; let it write its own memory |
| Agent's daily task reminders | 2 — `HEARTBEAT.md` | Message the agent |
| Agent's tool documentation | 2 — `TOOLS.md` | Prefer messaging; direct edit OK if agent is non-responsive |
| Agent RUNBOOK (scripts, paths) | 2 — `workspace/{agent}/RUNBOOK.md` | Message agent first; direct edit if broken/offline |

### The notification rule in practice

When we change something in Layer 1 that an agent depends on, send a message through
mhive (the chief of staff Telegram bot) formatted as:

```
@agent-name: Infrastructure update — [brief description of what changed and
why it matters to them]. Please update your RUNBOOK/SOUL/MEMORY as needed.
```

Example from the 2026-02-23 session: after rebuilding the Python venv in the container,
we drafted a message for the user to send to PolyHive Scout and Trader agents telling
them the activation path changed from `.venv/bin/activate` to `venv/bin/activate`.

---

## openclaw.json — The Gateway Config (Layer 1)

Located at `/root/.openclaw/openclaw.json` on the VPS. This is the single source of
truth for everything the gateway runs. Key sections:

```
meta        — version, name
wizard      — setup wizard config
auth        — model auth config (profile names/modes; keys resolve via env vars
              — see "Secrets Management" section below)
models      — model aliases and fallbacks
agents      — agent defaults (model, fallback chain); agent IDs are directory names
              under /root/.openclaw/workspace/
tools       — tool enable/disable config
bindings    — which agent handles which Telegram account
             (e.g. agentId:"main" → accountId:"mhive")
messages    — message delivery config
channels    — channel config (currently: telegram only)
             channels.telegram.accounts.{mhive,percy,bookworm} — bot tokens + allowlists
talk        — TTS config (talk.apiKey uses ${ELEVENLABS_API_KEY} from env)
gateway     — HTTP port, auth
skills      — skill paths
plugins     — plugin config
```

**Telegram bot tokens** are hardcoded in `openclaw.json` (in the channels config).
They are less sensitive (bot-only, not account credentials) but should eventually be
templated via 1Password.

---

## Secrets Management — Zero Hardcoded Keys (Layer 1)

**All secrets are injected from 1Password via Docker environment variables.**
No API keys, tokens, or credentials are stored in files on disk.

### How it works

```
1Password vault "OpenClaw"
  ↓  (op inject)
mhive-ops/.env.vps.tpl  →  .env  (on VPS, generated at deploy time)
  ↓  (docker compose)
Docker env vars  →  gateway container
  ↓  (runtime resolution)
openclaw.json uses ${VAR} refs  →  resolved from env at config load
agents use env var fallback     →  resolved from env at API call time
```

### Key resolution order (`src/agents/model-auth.ts`)

When an agent's model specifies a provider (e.g., `xai/grok-4-1-fast`), the gateway
resolves the API key in this order:

1. **auth-profiles.json** — per-agent file, checked first (currently empty for all agents)
2. **Environment variables** — `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `XAI_API_KEY`,
   `GEMINI_API_KEY`, etc.
3. **Config `apiKey`** — `models.providers[provider].apiKey` in `openclaw.json`
   (uses `${VAR}` env var substitution, not hardcoded values)

### Current state (as of 2026-02-27)

- **Docker env vars** (injected from 1Password via `mhive-ops/.env.vps.tpl`):
  `OPENAI_API_KEY`, `XAI_API_KEY`, `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`,
  `MAPLE_API_KEY`, `BRAVE_API_KEY`, `ELEVENLABS_API_KEY`
- **Per-agent auth-profiles.json** are empty — all agents use env var fallback
- **`openclaw.json`** uses `${VAR}` references for `models.providers.maple.apiKey`
  and `talk.apiKey` — resolved from env at config load time
- **1Password vault "OpenClaw"** is the single source of truth for all secrets
- **VPS 1Password access:** service account token at `/root/.op-service-account-token`
- **VPS `.env` injection:** `op inject -f -i mhive-ops/.env.vps.tpl -o .env`
- **Staging `.env` injection:** `start.sh` runs `op inject` from `.env.staging.tpl`

### Adding a new secret

1. Add to 1Password vault "OpenClaw" (API_CREDENTIAL type, `credential` field)
2. Add `op://` template reference in `mhive-ops/.env.vps.tpl` and `.env.staging.tpl`
3. Add env var to `docker-compose.override.yml` (VPS) and `docker-compose.staging.yml`
4. Re-run `op inject -f` and `docker compose up -d`

### Deploying to a new environment

1. Set up 1Password service account with access to vault "OpenClaw"
2. Store token at `~/.op-service-account-token`
3. Copy `mhive-ops/.env.vps.tpl` and run `op inject`
4. `docker compose up -d` — all secrets resolve from env vars

---

## WhatsApp — The Right Way to Connect It

The WhatsApp channel is **fully implemented** in the gateway source
(`src/channels/plugins/agent-tools/whatsapp-login.ts`). The intended flow is:

1. Message mhive via Telegram: *"Connect WhatsApp for yourself"*
2. mhive calls the `whatsapp_login` agent tool
3. The tool generates a QR code and sends it back as an image
4. You scan it on your phone
5. The session token is written into `openclaw.json` automatically

**Do not** manually construct a WhatsApp config in `openclaw.json`. The pairing/auth
flow writes a session blob that the Baileys library needs — it's not a simple token.

---

## Agent Roster (The Hive)

All 14 agents live as directories under `/root/.openclaw/workspace/`:

```
workspace/
├── AGENTS.md, SOUL.md, MEMORY.md, USER.md   ← mhive's (main agent) files
├── the-hive/                                 ← PolyHive trading scripts + venv
├── hive-scout/                               ← Polymarket market scanner
├── hive-trader/                              ← Polymarket order execution
├── hive-analyst/                             ← Analysis agent
├── hive-auditor/                             ← Audit agent
├── hive-contrarian/                          ← Contrarian view agent
├── hive-pm/                                  ← PolyHive PM (runs via @percy bot)
├── hive-quant/                               ← Quant agent
├── hive-risk/                                ← Risk agent
└── book-hive/                                ← BookHive directory
    ├── book-pm/
    ├── book-editor/
    ├── book-researcher/
    ├── book-publisher/
    └── book-marketing/
```

Telegram bindings (from `openclaw.json`):
- `@mhive bot` → `agentId: main` (mhive, chief of staff)
- `@percy bot` → `agentId: hive-pm` (PolyHive PM)
- `@bookworm bot` → `agentId: book-pm` (BookHive PM)

---

## Deployment Flow

```
Mac (~/Projects/openclaw/)
  │  git push → github.com/mmaghsoodnia/openclaw
  │
VPS (root@100.71.224.113, /root/openclaw/)
  │  git pull origin main
  │  docker compose build gateway
  │  docker compose up -d
  │
  └── Script: mhive-ops/deploy-vps.sh [--skip-push] [--skip-build]
```

The VPS pulls from **our fork** (`mmaghsoodnia/openclaw`), never from upstream. Upstream
changes must be deliberately merged into our fork first and reviewed.

---

## Session Start Checklist (for any future Claude/operator session)

1. Read `TODO.md` at project root
2. Read latest session log in `mhive-ops/sessions/`
3. Read this file (`mhive-ops/ARCHITECTURE.md`)
4. Before any change: ask "Is this Layer 1 or Layer 2?"
5. If Layer 2: notify the agent first via mhive Telegram
6. At session end: write `mhive-ops/sessions/YYYY-MM-DD.md`
