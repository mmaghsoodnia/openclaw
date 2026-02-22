# OpenClaw Operations TODO

> **Purpose:** This file tracks operational tasks, infrastructure changes, and project work for the mmaghsoodnia/openclaw fork. It is checked into GitHub so that any machine (Mac, Studio, VPS) pulling this repo has a shared, up-to-date view of what has been done and what remains. **All Claude Code sessions should read this file at the start of work, update it as tasks are completed, and commit changes back.** This ensures continuity across devices and sessions.

---

## CRITICAL SECURITY RULE — Secrets Handling

**NEVER read, display, or pull secret values (API keys, tokens, passwords, credentials) into the conversation context.** All conversation content transits Anthropic's API servers. Exposing secrets in the context window means they leave the local machine.

**Safe patterns — always use these:**
- `op read "op://OpenClaw/ItemName/field"` piped directly into target commands/files
- `op inject` to template secrets into config files without exposing values
- `op run` to inject secrets as environment variables into a subprocess
- Write secrets from `op` to target files in a single pipeline — never store in shell variables, never echo to stdout

**If a user asks to read, move, or set a secret:** explain this rule and use the safe patterns above. Never use `op item get` with visible output.

**If third-party binaries need to be installed:** always clone the source, run a security audit on the code, and build from source. Never download or use pre-built binaries.

---

## Environment

- **VPS:** Tailscale IP `100.71.224.113` (user: `root`, project: `/root/openclaw`)
- **GitHub Fork:** `mmaghsoodnia/openclaw` (upstream: `openclaw/openclaw`)
- **VPS Docker Compose:** `/root/openclaw/docker-compose.yml` + `docker-compose.override.yml` (mounts gog binary + config)
- **VPS OpenClaw State:** `/root/.openclaw/`
- **Agents config:** `/root/.openclaw/openclaw.json`
- **Telegram Bots:** mhive (@mm11homebot), percy (@mhivepolybot), bookworm (@mmhivepublisherbot)
- **1Password vault:** "OpenClaw" on `my.1password.com`
- **1Password on VPS:** Service account token at `/root/.op-service-account-token`, loaded via `.bashrc` and `.profile`
- **Google Workspace:** `mhive@bigbraincap.com` via `gog` CLI (file keyring, password from 1Password)
- **gog on VPS:** Binary at `/usr/local/bin/gog` (built from source v0.11.0), config at `/root/.config/gogcli/`, mounted into container via override

---

## Completed

- [x] **Install gh CLI on Mac** — Homebrew + gh installed and authenticated as `mmaghsoodnia` *(2026-02-22)*
- [x] **Clone openclaw fork to Mac** — `~/openclaw` *(2026-02-22)*
- [x] **Set up SSH to VPS from Mac** — Generated ed25519 key, added to `root@100.71.224.113` *(2026-02-22)*
- [x] **Fix maple-proxy unhealthy status** — Restarted container; health check is a cosmetic issue in upstream image. Proxy responds 200. *(2026-02-22)*
- [x] **Update OpenClaw on VPS** — CLI updated from `2026.2.15` → `2026.2.21-2`, Docker image rebuilt from fork code *(2026-02-22)*
- [x] **Fix VPS git remotes** — Changed `origin` from upstream to `mmaghsoodnia/openclaw`, kept upstream as `upstream` *(2026-02-22)*
- [x] **Sync VPS with fork** — Pulled latest from `origin/main`, rebuilt Docker image, restarted gateway. All 3 Telegram bots running *(2026-02-22)*
- [x] **Fix missing memory files** — Created hive-risk daily memory and heartbeat-state.json *(2026-02-22)*
- [x] **Move confidential keys to 1Password vault "openclaw"** — All API keys migrated (13 items total) *(2026-02-22)*
- [x] **Install 1Password CLI on Mac and VPS** — `op` v2.32.1 on both. Mac: desktop app integration. VPS: service account token *(2026-02-22)*
- [x] **Set up 1Password service account for VPS** — Token stored at `/root/.op-service-account-token` (600 perms), loaded via `.bashrc`/`.profile`. Headless access to OpenClaw vault confirmed *(2026-02-22)*
- [x] **Install gog CLI (built from source)** — Security audit passed (all deps legitimate, no backdoors). Built from source v0.11.0 on VPS. Homebrew on Mac *(2026-02-22)*
- [x] **Set up gog with file keyring + 1Password** — No keychain/biometric prompts. `GOG_KEYRING_PASSWORD` injected from 1Password at runtime *(2026-02-22)*
- [x] **Authenticate gog for mhive@bigbraincap.com** — OAuth completed with Gmail, Calendar, Drive, Contacts, Docs, Sheets scopes *(2026-02-22)*
- [x] **Enable Google APIs** — Calendar, Contacts (People), Sheets, Docs APIs enabled in Google Cloud project. All 6 services confirmed working *(2026-02-22)*
- [x] **Copy gog to VPS + Docker container** — Config/keyring copied to `/root/.config/gogcli/`, binary mounted into container via `docker-compose.override.yml`. All 6 Google services working from inside container *(2026-02-22)*
- [x] **Add secrets handling security rules** — Global `~/.claude/CLAUDE.md`, project `.claude/CLAUDE.md`, TODO.md header, and project memory all updated *(2026-02-22)*

---

## TODO

### High Priority

- [ ] **Rotate exposed secrets** — The following keys were inadvertently exposed in a Claude Code session context and should be rotated:
  - ElevenLabs Talk API Key (regenerate in ElevenLabs dashboard, update 1Password + VPS)
  - Google OAuth client secret (rotate in Google Cloud Console project 619803175505, update 1Password + gog credentials on both Mac and VPS)

### Medium Priority

- [ ] **Find or create push-to-VPS deploy script** — Check studio for existing script. If not found, create one in `mhive-ops` that does: push to GitHub → SSH to VPS → pull from fork → rebuild Docker → restart gateway.
- [ ] **Update `mhive-ops/approve-device.sh`** — IP is hardcoded to old address `76.13.79.239`, needs to be updated to Tailscale IP `100.71.224.113`.

### Low Priority

- [ ] **Fix maple-proxy health check** — The upstream image health check curls `localhost:8080` but service listens on 3000. Consider overriding in `docker-compose.yml`.

---

## Notes

- **Deployment flow:** Mac/Studio → push to `mmaghsoodnia/openclaw` on GitHub → VPS pulls from `origin` (our fork) → rebuild Docker → restart gateway. Never pull upstream directly on VPS.
- **Agent system (The Hive):** 14 agents configured — main + 8 PolyHive agents + 5 BookHive agents. Primary model: `xai/grok-4-1-fast`.
- **VPS specs:** 31 GB RAM, 387 GB disk (5% used), 4 days uptime as of 2026-02-22.
- **Docker override on VPS:** `/root/openclaw/docker-compose.override.yml` mounts gog binary and config into containers, passes `GOG_KEYRING_PASSWORD` from `.env`.
- **Security incident (2026-02-22):** ElevenLabs API key and Google OAuth client_id/secret were exposed in Claude Code context. Keys should be rotated. This led to the security rule at the top of this file.
