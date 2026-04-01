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

| What you want to change        | Layer                                   | Correct approach                                                                 |
| ------------------------------ | --------------------------------------- | -------------------------------------------------------------------------------- |
| ElevenLabs API key             | 1 — `openclaw.json` `talk.apiKey`       | Edit directly via `op inject` or template                                        |
| Google OAuth secret            | 1 — `gog` config + 1Password            | Rotate in Google Cloud, update 1Password, re-auth gog                            |
| Python packages in container   | 1 — Dockerfile or startup script        | Add to Dockerfile; send mhive notification about new venv path                   |
| Add WhatsApp channel           | 1 — `openclaw.json` channels + auth     | Trigger `whatsapp_login` agent tool via mhive Telegram message                   |
| Enable voice for an agent      | 1 — `openclaw.json` `talk` config       | Edit directly                                                                    |
| New agent system prompt rules  | 1 — gateway source (`system-prompt.ts`) | Code change → build → deploy                                                     |
| Agent's personality or mission | 2 — `SOUL.md`                           | Send mhive a message explaining the change; let the agent update its own SOUL.md |
| Agent's long-term memory       | 2 — `MEMORY.md`                         | Message the agent; let it write its own memory                                   |
| Agent's daily task reminders   | 2 — `HEARTBEAT.md`                      | Message the agent                                                                |
| Agent's tool documentation     | 2 — `TOOLS.md`                          | Prefer messaging; direct edit OK if agent is non-responsive                      |
| Agent RUNBOOK (scripts, paths) | 2 — `workspace/{agent}/RUNBOOK.md`      | Message agent first; direct edit if broken/offline                               |

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
             (e.g. agentId:"main" → accountId:"mhivemain")
messages    — message delivery config
channels    — channel config (currently: telegram only)
             channels.telegram.accounts.{mhivemain,mhivepoly,mhivebook,mhivebrand,mhivedoost,mhiveresearch} — bot tokens + allowlists
talk        — TTS config (talk.apiKey uses ${ELEVENLABS_API_KEY} from env)
gateway     — HTTP port, auth
skills      — skill paths
plugins     — plugin config
```

**Telegram bot tokens** use `${VAR}` env var refs in `openclaw.json`, injected from
1Password via the same `op inject` pipeline as LLM API keys. Env vars:
`TELEGRAM_MHIVEMAIN_BOT_TOKEN`, `TELEGRAM_MHIVEPOLY_BOT_TOKEN`,
`TELEGRAM_MHIVEBOOK_BOT_TOKEN`, `TELEGRAM_MHIVEBRAND_BOT_TOKEN`,
`TELEGRAM_MHIVEDOOST_BOT_TOKEN`, `TELEGRAM_MHIVERESEARCH_BOT_TOKEN`.

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

### Current state (as of 2026-03-22)

- **Docker env vars** (injected from 1Password via `mhive-ops/.env.vps.tpl`):
  `OPENAI_API_KEY`, `XAI_API_KEY`, `GEMINI_API_KEY`, `ANTHROPIC_API_KEY`,
  `MAPLE_API_KEY`, `VENICE_API_KEY`, `DEEPSEEK_API_KEY`, `GROQ_API_KEY`,
  `BRAVE_API_KEY`, `ELEVENLABS_API_KEY`
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

### Docker volume mounts (VPS `docker-compose.override.yml`)

| Host path                          | Container path              | Mode | Purpose                                    |
| ---------------------------------- | --------------------------- | ---- | ------------------------------------------ |
| `/usr/local/bin/gog`               | `/usr/local/bin/gog`        | ro   | gog CLI binary (source-built, linux/amd64) |
| `/root/.config/gogcli`             | `/home/node/.config/gogcli` | ro   | gog OAuth credentials + keyring            |
| `/root/gog-mcp`                    | `/home/node/gog-mcp`        | ro   | gog MCP server (Node.js)                   |
| `/root/Projects/llm-bench/results` | `/data/llm-bench-results`   | ro   | LLM benchmark results (read by agents)     |

The default `docker-compose.yml` also mounts `/root/.openclaw` (config + workspace) via
the `OPENCLAW_CONFIG_DIR` env var. Volumes above are **additional** mounts from the override.

### Google Workspace (gog) credentials

gog requires three credential files inside the Docker container at `/home/node/.config/gogcli/`:

| File                           | Source                                 | 1Password item                                                                 |
| ------------------------------ | -------------------------------------- | ------------------------------------------------------------------------------ |
| `config.json`                  | Static (`{"keyring_backend": "file"}`) | N/A                                                                            |
| `credentials.json`             | OAuth client_id + client_secret        | "Google Workspace OAuth" (fields: `client_id`, `client_secret`)                |
| `keyring/token:*`              | Encrypted OAuth refresh tokens         | "GOG OAuth Tokens" (fields: `default_token`, `account_token` — base64-encoded) |
| `GOG_KEYRING_PASSWORD` env var | Decrypts the keyring                   | "GOG Keyring Password" (field: `password`)                                     |

**VPS:** Files live on disk at `/root/.config/gogcli/`, mounted via `docker-compose.override.yml`.
The keyring password is injected as an env var from `.env.vps.tpl`.

**Staging:** Files are reconstructed from 1Password by `mhive-ops/staging/setup-gog.sh` into
`~/.openclaw-staging/gogcli/`, mounted via `docker-compose.staging.yml`. The script:

1. Writes static `config.json`
2. Uses `op inject` with `.gogcli-credentials.tpl` for `credentials.json`
3. Uses `op read` + base64 decode for keyring token files
4. The keyring password comes via `.env.staging` (same as other env vars)

Both `start.sh` and `rebuild.sh` call `setup-gog.sh` automatically.

### Google Workspace MCP server (gog-mcp)

As of 2026-03-27, agents access Google Workspace via a dedicated **MCP server** (`gog-mcp`)
instead of the old Lobster plugin subprocess approach. The MCP server provides 30+ structured
tools (Gmail, Calendar, Drive, Docs with rich formatting, Sheets, Contacts).

**Source:** `~/Projects/gog/` (private repo `mmaghsoodnia/gog-mcp`). Uses a source-built
`gogcli` binary from `~/Projects/gogcli/` (upstream: `steipete/gogcli`, MIT license).

**Registration in `openclaw.json`:**

```json
{
  "mcp": {
    "servers": {
      "gog": {
        "command": "node",
        "args": ["/home/node/gog-mcp/dist/index.js"],
        "env": {
          "GOG_PATH": "/usr/local/bin/gog",
          "GOG_ACCOUNT": "mhive@bigbraincap.com",
          "GOG_KEYRING_PASSWORD": "${GOG_KEYRING_PASSWORD}"
        }
      }
    }
  }
}
```

The MCP server is spawned lazily by the gateway on first tool call. It shells out to the
`gog` CLI binary for each operation. Secrets (`GOG_KEYRING_PASSWORD`) flow from `.env` →
Docker env → `openclaw.json` `${VAR}` resolution → MCP server env.

**Redeployment** (after changes to gog-mcp or gogcli):

1. Cross-compile gogcli: `cd ~/Projects/gogcli && GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o gog-linux-amd64 ./cmd/gog/`
2. Package gog-mcp: `cd ~/Projects/gog && tar czf /tmp/gog-mcp.tar.gz dist/ node_modules/ package.json`
3. Upload: `scp` binary to `/usr/local/bin/gog`, tarball to `/root/`, extract to `/root/gog-mcp/`
4. Restart gateway: `docker compose up -d openclaw-gateway`

### Deploying to a new environment

1. Set up 1Password service account with access to vault "OpenClaw"
2. Store token at `~/.op-service-account-token`
3. Copy `mhive-ops/.env.vps.tpl` and run `op inject`
4. Run `mhive-ops/staging/setup-gog.sh` to reconstruct gog credentials
5. `docker compose up -d` — all secrets resolve from env vars

---

## WhatsApp — The Right Way to Connect It

The WhatsApp channel is **fully implemented** in the gateway source
(`src/channels/plugins/agent-tools/whatsapp-login.ts`). The intended flow is:

1. Message mhive via Telegram: _"Connect WhatsApp for yourself"_
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

- `@mhivemainbot` → `agentId: main` (mhive, chief of staff) — account: `mhivemain`
- `@mhivepolybot` → `agentId: hive-pm` (PolyHive PM) — account: `mhivepoly`
- `@mhivebookbot` → `agentId: book-pm` (BookHive PM) — account: `mhivebook`
- `@mhivebrandbot` → unbound (brand bot, disabled) — account: `mhivebrand`
- `@mhivedoostbot` → `agentId: doost` — account: `mhivedoost`
- `@mhiveresearchbot` → `agentId: researcher` (Vega, Research) — account: `mhiveresearch`

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

**Last upstream merge:** 2026-03-22 (1,329 commits, fork commit `f832d0b48f`). Key upstream
changes: per-agent defaults (#51974 — optional `thinkingDefault`/`reasoningDefault`/`fastModeDefault`),
Discord message dedup, startup perf, plugin resolver cache fix. Our plugin runtime fix
(`plugins/runtime/index` build entry) is now upstream natively.

---

## VPS Security Hardening (2026-03-10)

Four layers of inbound protection, all active:

| Layer                        | What                                                                                              | Config location                                     |
| ---------------------------- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| **Hostinger cloud firewall** | Allow TCP 22 (SSH) + UDP 41641 (Tailscale WireGuard), drop all else                               | Hostinger API — firewall group `mhive` (ID 234443)  |
| **DOCKER-USER iptables**     | Ports 18789-18790 locked to Tailscale interface only; conntrack allows container outbound replies | VPS `/etc/network/if-pre-up.d/docker-user-firewall` |
| **SSH hardening**            | Key-only auth, no passwords, max 3 attempts, no root password login                               | VPS `/etc/ssh/sshd_config.d/01-hardening.conf`      |
| **fail2ban**                 | 3 SSH failures → 24h ban, Tailscale IPs whitelisted                                               | VPS `/etc/fail2ban/jail.local`                      |

**Key details:**

- All management access goes through **Tailscale** (IP `100.71.224.113`). Public IP `76.13.79.239` is firewalled.
- Docker bypasses UFW — the `DOCKER-USER` chain is the only way to restrict Docker-published ports. The chain must include a `conntrack --ctstate RELATED,ESTABLISHED` RETURN rule before the final DROP, otherwise container outbound connections (Telegram, Google, etc.) break because return traffic gets dropped. Fixed 2026-03-12.
- `01-hardening.conf` must sort before `50-cloud-init.conf` (OpenSSH first-match-wins).
- Hostinger firewall is inbound-only — all outbound connections (Google APIs, Telegram, 1Password, Polymarket) are unaffected.
- UDP 41641 (Tailscale/WireGuard) silently drops unauthenticated packets — not an attack vector.
- Hostinger MCP server available for managing cloud firewall: `mhive-ops/hostinger-mcp-run.sh` (registered in `~/.claude.json`).

---

## Outbound Traffic Security Assessment (2026-03-25)

The four layers above cover **inbound** protection. This section documents the assessment of
whether outbound traffic needs an additional privacy/security layer (VPN, Tor, proxy).

**Conclusion: not needed.** The current architecture is sufficient.

### Current outbound posture

All outbound connections from the VPS (API calls, Telegram, Google, GitHub, 1Password) use
HTTPS/TLS. Content is encrypted in transit. Hostinger/ISP can see destination IPs and traffic
volume but not request/response content.

### Identity binding makes IP anonymity ineffective

Every external service the VPS talks to identifies the caller by credential, not by IP:

| Service           | Identity mechanism                | IP-based tracking? |
| ----------------- | --------------------------------- | ------------------ |
| Anthropic, OpenAI | API key in `Authorization` header | No                 |
| xAI, Gemini, Groq | API key in `Authorization` header | No                 |
| Telegram          | Bot token in URL path             | No                 |
| Google Workspace  | OAuth refresh token               | No                 |
| 1Password         | Service account token             | No                 |
| GitHub            | SSH key / PAT                     | No                 |

A VPN would hide the VPS IP from these services, but the API key already tells them exactly
who is calling. Changing the source IP provides no additional privacy.

### VPN trade-off

A VPN shifts trust from Hostinger/ISP to the VPN provider — it does not eliminate trust.
The VPN provider can see all destination IPs and traffic patterns (same visibility the ISP
currently has). Additional downsides: latency increase on every API call, new single point
of failure, monthly cost, and operational complexity (key rotation, reconnect logic).

### Tor assessment

Tor is unsuitable for this system:

- **Latency:** 2-10x slower per request — unacceptable for agent responsiveness
- **Telegram:** Long-polling breaks on Tor; many exit nodes are blocked
- **API providers:** Most block or rate-limit Tor exit nodes
- **Reliability:** Exit node churn causes connection drops — bad for 24/7 agent system

### When to revisit

If agents begin heavy **web scraping or public browsing** (via `web_fetch`/`browser` tools)
where hiding the VPS IP from target websites matters (anti-blocking, anti-fingerprinting),
consider adding a lightweight outbound SOCKS proxy or rotating residential proxy for those
specific tool calls only — not system-wide. This is not needed with current usage patterns.

### Real attack surfaces (where to focus instead)

| Surface                  | Current mitigation                        | Status |
| ------------------------ | ----------------------------------------- | ------ |
| Secrets in context       | 1Password injection, never in prompts     | Good   |
| Agent prompt injection   | Tool approval system, allowlists          | Good   |
| SSH/management access    | Tailscale-only, key auth, fail2ban        | Good   |
| Container isolation      | Docker, restricted DOCKER-USER chain      | Good   |
| Outbound content privacy | HTTPS/TLS on all connections              | Good   |
| Outbound IP anonymity    | Not needed — identity is credential-bound | N/A    |

---

## Agent Workspace Sync

Before testing anything on staging, **always sync the agent workspace from VPS**:

```
bash mhive-ops/staging/sync-workspace.sh
```

This SSHs to the VPS, creates a tar backup of the workspace (excluding venvs and
node_modules), downloads it, and extracts to `~/.openclaw-staging/workspace/`.

**Why:** Agent workspace files (SOUL.md, MEMORY.md, sessions, RUNBOOK.md, etc.) are
the agents' minds. Testing against stale workspace data means testing against agents
that don't know what they know in production — leading to false confidence in staging.

The sync is built into `start.sh` (step 1) and `rebuild.sh` (first step). If the VPS
is unreachable, the scripts fall back to existing workspace files but warn you.

The VPS-side backup script is at `/root/openclaw/mhive-ops/backup-workspace.sh`.

---

## Emergency Procedures

### Cost Kill Switch — Stop Runaway Agent Spending

When agents are generating too much API spend, use this two-lever kill switch via the
gateway config. **Do NOT disable channels or Telegram** — that severs communication and
requires SSH to restore.

**Kill switch** (patch via `gateway` tool `config.patch`, or edit `openclaw.json` on VPS):

```json
{
  "cron": { "enabled": false },
  "agents": { "defaults": { "heartbeat": { "every": "" } } }
}
```

**Resume** (reverse both settings):

```json
{
  "cron": { "enabled": true },
  "agents": { "defaults": { "heartbeat": { "every": "30m" } } }
}
```

**Effect:** Stops all scheduled cron jobs and heartbeat polling. Telegram stays live so
you can tell mhive to activate/deactivate via a message. Gateway restarts automatically
after config patch (~5s). Inbound messages still work during the kill switch.

**To trigger via mhive:** Say _"Emergency stop — kill the spending"_. mhive will apply
the patch and confirm back via Telegram. To resume: _"Resume normal operations"_.

---

## Agent Model Matrix (Layer 1)

Model assignments are in `openclaw.json` under `agents.list[].model` and `agents.defaults.model`.
The gateway hot-reloads config changes — no restart needed.

| Category    | Agents                                                            | Primary                     | Why                                  |
| ----------- | ----------------------------------------------------------------- | --------------------------- | ------------------------------------ |
| Planners    | mhive, hive-pm, hive-risk, book-pm                                | anthropic/claude-sonnet-4-6 | Quality critical (4.7/5), $0.12/call |
| Researchers | scout, analyst, contrarian, quant, auditor, book-researcher, etc. | xai/grok-4-1-fast           | Best value (3.0/5), $0.003/call, 22s |
| Doers       | hive-trader, book-publisher                                       | xai/grok-4-1-fast           | Speed + value, same as researchers   |

All agents have fallback chains: primary → fallback 1 → fallback 2. See `openclaw.json` for exact chains.

**Benchmark framework:** Separate project at `~/Projects/llm-bench/` (split from openclaw 2026-03-20).
Run `bash run-benchmark.sh` on VPS to test new models before assigning them. See `llm-bench/CLAUDE.md`
for full workflow, scoring criteria, and how to apply changes to production.

**Last benchmarked:** 2026-03-13 (8 models x 3 prompts). Results in `llm-bench/results/2026-03-13/summary.md`.

---

## Mhive Health Monitoring & Authority (2026-03-14)

Mhive (chief of staff) now has a health monitoring system and defined authority for fixing agent issues.

### Health diagnostic tool

`workspace/the-hive/scripts/hive-health.py` — reads session data, workspace files, delivery queue,
and gateway logs across ALL teams. Produces structured Markdown report with per-agent metrics.

```
python3 /home/node/.openclaw/workspace/the-hive/scripts/hive-health.py \
  --home /home/node/.openclaw --output HEALTH.md
```

Flags: STALE (2–5d inactive), DEAD (5d+), NO-RUNBOOK, NO-MEMORY. Reports delivery queue status,
recent errors, config changes. Mhive runs this every other day (HEARTBEAT.md Priority 0).

### Mhive authority model

**Can do directly (no MM approval):**

- Swap agent models (following HEURISTICS.md)
- Fix/rewrite RUNBOOKs, clean corrupt memory files
- Enable/disable heartbeats, adjust cron schedules
- Diagnose and fix broken agent sessions

**Requires MM approval (via `workspace/RESTRUCTURE.md`):**

- Removing an agent entirely
- Replacing an agent with a cron job/script
- Adding a new agent
- Changing pipeline structure
- Cost changes >$1/day

### Workspace files updated (Layer 2 — deployed to VPS + staging)

| File                    | Change                                                                                                  |
| ----------------------- | ------------------------------------------------------------------------------------------------------- |
| `HEARTBEAT.md`          | Priority 0: health review every other day                                                               |
| `SOUL.md`               | Lifecycle v2026-03-14: role audit + health monitoring steps                                             |
| `MEMORY.md`             | 3 lessons: not every role needs an agent, model churn corrupts memory, health monitoring is mhive's job |
| `HEURISTICS.md`         | 2 anti-patterns: agent for a script job, model churn without memory cleanup                             |
| `SCORECARD-TEMPLATE.md` | Role audit pre-bootstrap gate, health monitoring ongoing section                                        |
| `AGENTS.md`             | Bootstrap checklist: role audit (#1) + health monitoring (#9)                                           |
| `TOOLS.md`              | Health script documentation                                                                             |
| `RESTRUCTURE.md`        | New — structural change proposal template                                                               |

### Key insight from Scout diagnosis

Scout (market scanner) was an LLM agent wrapping a deterministic script. 3+ weeks broken due to
model churn corrupting memory, weak models hallucinating data. **Rule: before assigning Tier 1,
ask "Does this need an LLM at all?" If run-script→filter→forward with no judgment, use a cron job.**

---

## PolyHive Team

Full design: `the-hive/TEAMDESIGN.md` (on VPS at `/home/node/.openclaw/workspace/the-hive/TEAMDESIGN.md`).

Pipeline redesigned 2026-03-29. Root cause of 13-day zero-trade drought: scanner path mismatch.
New design: deterministic scripts handle all verification; agents provide judgment only (2 LLM calls/day).
Cron: `scan.py` at 14:00 UTC triggers event-driven chain → analyst → contrarian → sizing → paper trade.
Health check: `pipeline-health.py` at 17:00 UTC → Percy → mhive Telegram daily.

---

## Mhive OS v2 — Fractal Operating System (2026-03-22)

The agent system now runs a two-level fractal operating system:

### Level 1: PM Operating System (Percy, Book PM)

Each PM is an operator of their team. They maintain:

- `{pm}/SCORECARD.md` — Live KPIs, updated daily as Step 1 of morning protocol
- `{pm}/OPEN.md` — Active fixes + experiments (hypothesis → metric → deadline)
- `{pm}/BACKLOG.md` — Prioritized improvement ideas (Impact × Confidence ÷ Effort)
- `{pm}/memory/weekly-YYYY-MM-DD.md` — Structured weekly report (due Friday 12:00 UTC)

PMs coach their agents, run experiments, and escalate to mhive after 2 failed attempts.

### Level 2: Mhive Meta-Operating System

Mhive is the operator of operators. Core responsibilities:

- **Verify** PM scorecards against ground truth (`VERIFICATION-MAP.md`)
- **Grade** PMs weekly on output AND accuracy (lower of two = overall grade)
- **Allocate** token budget per team based on verified results
- **Report** to MM: daily 2-line pulse (09:00 UTC) + Friday weekly review
- **Escalate** with data when coaching fails (5-stage ladder: coach → investigate → escalate)

### Key Files

| File                  | Location       | Owner | Purpose                                |
| --------------------- | -------------- | ----- | -------------------------------------- |
| `VERIFICATION-MAP.md` | workspace root | Mhive | Ground truth sources per metric        |
| `WEEKLY-REVIEW.md`    | workspace root | Mhive | Friday review (written weekly)         |
| `templates/pm-os/`    | workspace dir  | Mhive | Reusable PM OS templates for new teams |
| `{pm}/SCORECARD.md`   | per-PM dir     | PM    | Live KPIs                              |
| `{pm}/OPEN.md`        | per-PM dir     | PM    | Experiments + fixes                    |
| `{pm}/BACKLOG.md`     | per-PM dir     | PM    | Improvement ideas                      |

### Rollback

Pre-v2 workspace backup: `/root/workspace-backup-2026-03-22.tar.gz`
Week 4 assessment (2026-04-19): compare leading indicators (OS adoption) and lagging indicators
(outcomes) against Day 0 baseline captured in `mhive-ops/sessions/2026-03-22.md`.

---

## Session Start Checklist (for any future Claude/operator session)

1. Read `TODO.md` at project root
2. Read latest session log in `mhive-ops/sessions/`
3. Read this file (`mhive-ops/ARCHITECTURE.md`)
4. **Sync agent workspace from VPS** — `bash mhive-ops/staging/sync-workspace.sh`
5. Before any change: ask "Is this Layer 1 or Layer 2?"
6. If Layer 2: notify the agent first via mhive Telegram
7. At session end: write `mhive-ops/sessions/YYYY-MM-DD.md`
