# OpenClaw Operations TODO

> **Purpose:** This file tracks operational tasks, infrastructure changes, and project work for the mmaghsoodnia/openclaw fork. It is checked into GitHub so that any machine (Mac, Studio, VPS) pulling this repo has a shared, up-to-date view of what has been done and what remains. **All Claude Code sessions should read this file at the start of work, update it as tasks are completed, and commit changes back.** This ensures continuity across devices and sessions.
>
> **Session logs:** Detailed session history lives in `mhive-ops/sessions/` (one file per session, named `YYYY-MM-DD.md`). Read these for context on past work. **Write a new session log at the end of every session.**

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

- [x] **Install gh CLI on Mac** — Homebrew + gh installed and authenticated as `mmaghsoodnia` _(2026-02-22)_
- [x] **Clone openclaw fork to Mac** — `~/openclaw` _(2026-02-22)_
- [x] **Set up SSH to VPS from Mac** — Generated ed25519 key, added to `root@100.71.224.113` _(2026-02-22)_
- [x] **Fix maple-proxy unhealthy status** — Restarted container; health check is a cosmetic issue in upstream image. Proxy responds 200. _(2026-02-22)_
- [x] **Update OpenClaw on VPS** — CLI updated from `2026.2.15` → `2026.2.21-2`, Docker image rebuilt from fork code _(2026-02-22)_
- [x] **Fix VPS git remotes** — Changed `origin` from upstream to `mmaghsoodnia/openclaw`, kept upstream as `upstream` _(2026-02-22)_
- [x] **Sync VPS with fork** — Pulled latest from `origin/main`, rebuilt Docker image, restarted gateway. All 3 Telegram bots running _(2026-02-22)_
- [x] **Fix missing memory files** — Created hive-risk daily memory and heartbeat-state.json _(2026-02-22)_
- [x] **Move confidential keys to 1Password vault "openclaw"** — All API keys migrated (13 items total) _(2026-02-22)_
- [x] **Install 1Password CLI on Mac and VPS** — `op` v2.32.1 on both. Mac: desktop app integration. VPS: service account token _(2026-02-22)_
- [x] **Set up 1Password service account for VPS** — Token stored at `/root/.op-service-account-token` (600 perms), loaded via `.bashrc`/`.profile`. Headless access to OpenClaw vault confirmed _(2026-02-22)_
- [x] **Install gog CLI (built from source)** — Security audit passed (all deps legitimate, no backdoors). Built from source v0.11.0 on VPS. Homebrew on Mac _(2026-02-22)_
- [x] **Set up gog with file keyring + 1Password** — No keychain/biometric prompts. `GOG_KEYRING_PASSWORD` injected from 1Password at runtime _(2026-02-22)_
- [x] **Authenticate gog for mhive@bigbraincap.com** — OAuth completed with Gmail, Calendar, Drive, Contacts, Docs, Sheets scopes _(2026-02-22)_
- [x] **Enable Google APIs** — Calendar, Contacts (People), Sheets, Docs APIs enabled in Google Cloud project. All 6 services confirmed working _(2026-02-22)_
- [x] **Copy gog to VPS + Docker container** — Config/keyring copied to `/root/.config/gogcli/`, binary mounted into container via `docker-compose.override.yml`. All 6 Google services working from inside container _(2026-02-22)_
- [x] **Add secrets handling security rules** — Global `~/.claude/CLAUDE.md`, project `.claude/CLAUDE.md`, TODO.md header, and project memory all updated _(2026-02-22)_
- [x] **Create push-to-VPS deploy script** — `mhive-ops/deploy-vps.sh` with `--skip-push` and `--skip-build` flags. Pushes to GitHub → pulls on VPS → rebuilds Docker → restarts gateway _(2026-02-22)_
- [x] **Update `mhive-ops/approve-device.sh` IP** — Changed from old public IP `76.13.79.239` to Tailscale IP `100.71.224.113` _(2026-02-22)_
- [x] **Fix maple-proxy health check** — Added maple-proxy service to `docker-compose.override.yml` on VPS with corrected health check on port 3000. Container now reports healthy _(2026-02-22)_
- [x] **Move project to `~/Projects/openclaw/`** — Relocated from `~/openclaw/` to correct path, merged `.claude` configs, verified git integrity _(2026-02-22)_
- [x] **Install Node.js + pnpm on Mac** — Node.js 22.22.0 via Homebrew, pnpm 10.23.0 via corepack _(2026-02-22)_
- [x] **Verify local build + gateway** — `pnpm install` + `pnpm build` clean. Gateway tested in isolated mode (no channels, no agents) — HTTP 200 confirmed _(2026-02-22)_
- [x] **Fix PolyHive Polymarket betting** — Root cause: Python venv built with 3.14 on Mac Studio, container has 3.11. Fix: rebuilt venv inside Docker container, migrated Polymarket credentials to 1Password ("Polymarket Wallet" + "Polymarket API" items), created `.env.tpl` for `op inject`, redacted hardcoded private key from Trader RUNBOOK. Verified: `py_clob_client` import, market scanner (8 leagues, 113 events), wallet check (CLOB API connected, found live orders). Agent self-heal message sent via mhive. _(2026-02-23)_
- [x] **Rotate ElevenLabs Talk API Key** — Regenerated in ElevenLabs dashboard, updated in 1Password, injected into openclaw.json via `op inject`. _(2026-02-24)_
- [x] **Rotate Google OAuth client secret** — Rotated in Google Cloud Console, updated in 1Password, re-authenticated via `gog auth`. _(2026-02-24)_
- [x] **Make Python venv persistent in Docker** — Added `python3-pip python3-venv` to Dockerfile (committed to fork). Created `requirements.txt` in the-hive workspace with pinned versions. Added startup venv health-check wrapper to `docker-compose.override.yml` on VPS — gateway auto-bootstraps venv if missing/broken. Redeployed and verified. _(2026-02-24)_
- [x] **Disable WhatsApp channel** — Emergency fix after bot sent unsolicited pairing messages to contacts. Disabled both plugin and channel config on VPS. Baileys session preserved. See session log `2026-02-25.md`. _(2026-02-25)_
- [x] **Set up local staging environment** — Full Docker staging on Mac mirroring VPS. Scripts in `mhive-ops/staging/` (start/stop/rebuild/sync). Staging Telegram bot `@mhive_stage_bot` verified working end-to-end. _(2026-02-25)_
- [x] **Merge upstream/main into fork** — Updated fork from v2026.2.18 to latest upstream (2286 commits). Resolved Dockerfile conflict (kept python3-pip + upstream --chown). _(2026-02-25)_

---

## TODO

> **Architecture note:** Before working on any item below, read `mhive-ops/ARCHITECTURE.md`.
> Every item is tagged **[Layer 1 — Operator]** or **[Layer 2 — Agent]** so you know the
> correct approach without re-deriving it.

### High Priority

- [ ] **Update VPS to latest fork** — `[Layer 1 — Operator]`
  - Fork pushed to GitHub with upstream merge + staging scripts. VPS needs `git pull && docker build && docker compose restart`.
  - Tailscale must be running on Mac for SSH access to VPS.

- [ ] **Re-enable WhatsApp channel (currently disabled)** — `[Layer 1 — Operator]`
  - **Disabled 2026-02-25** due to security issues: default `dmPolicy: "pairing"` caused bot to auto-reply pairing codes to random contacts ([Issue #834](https://github.com/openclaw/openclaw/issues/834)), and allowlist bypass via persisted pairings ([Issue #22599](https://github.com/openclaw/openclaw/issues/22599)).
  - Baileys session still exists at `/root/.openclaw/credentials/whatsapp/default/`. Plugin disabled in `plugins.entries.whatsapp.enabled = false`, channel set to `dmPolicy: "disabled"`.
  - **Before re-enabling:** verify Issues #22599 and #25975 are fixed upstream, merge fixes into fork, use a dedicated number (not personal), and set `dmPolicy: "allowlist"`.
  - 1Password item "OpenClaw WhatsApp" (credential field) stores the allowFrom number for when this is re-enabled.

- [ ] **Enable voice for agents** — `[Layer 1 — Operator]`
  - ElevenLabs TTS is fully implemented in gateway (`src/tts/`). `talk.apiKey` wired in `openclaw.json`.
  - ElevenLabs key rotation is done — blocker cleared.
  - Steps: configure `talk` section per-agent in `openclaw.json` with desired voice IDs. No agent workspace changes needed — pure operator config.
  - Scope: Telegram voice notes first (simplest). PSTN and WhatsApp voice require additional channel setup.

---

## Notes

- **Architecture reference:** Full system architecture (two-layer model, context window construction, change ownership table) documented in `mhive-ops/ARCHITECTURE.md`. Read before making changes.
- **Deployment flow:** Mac/Studio → push to `mmaghsoodnia/openclaw` on GitHub → VPS pulls from `origin` (our fork) → rebuild Docker → restart gateway. Never pull upstream directly on VPS.
- **Agent system (The Hive):** 14 agents configured — main + 8 PolyHive agents + 5 BookHive agents. Primary model: `xai/grok-4-1-fast`.
- **Local dev (Mac):** Project at `~/Projects/openclaw/`, Node.js 22.22.0 (`/opt/homebrew/opt/node@22/bin`), pnpm 10.23.0 via corepack.
- **VPS specs:** 31 GB RAM, 387 GB disk (5% used), 4 days uptime as of 2026-02-22.
- **Docker override on VPS:** `/root/openclaw/docker-compose.override.yml` mounts gog binary and config into containers, passes `GOG_KEYRING_PASSWORD` from `.env`.
- **Security incident (2026-02-22):** ElevenLabs API key and Google OAuth client_id/secret were exposed in Claude Code context. Keys should be rotated. This led to the security rule at the top of this file.
- **Polymarket 1Password items (2026-02-23):** "Polymarket Wallet" (private_key, funder_address, chain_id, signature_type) and "Polymarket API" (host, gamma_api_base_url). `.env.tpl` on VPS at `/root/.openclaw/workspace/the-hive/.env.tpl` — regenerate `.env` via `op inject --account my.1password.com -i .env.tpl -o .env`.
- **Python venv ephemeral (2026-02-23):** The venv at `/root/.openclaw/workspace/the-hive/venv/` was built inside the Docker container (`docker exec`). It will be lost if the container is recreated. `python3-pip` and `python3-venv` were also installed via `apt-get` inside the container and are equally ephemeral.
- **Pre-existing Polymarket notes (2026-02-23):** Wallet address and funder address don't match (may indicate proxy/safe setup). Wallet has ~$200 USDC balance. The address mismatch was not caused by the VPS migration.
