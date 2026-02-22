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
- **VPS Docker Compose:** `/root/openclaw/docker-compose.yml`
- **VPS OpenClaw State:** `/root/.openclaw/`
- **Agents config:** `/root/.openclaw/openclaw.json`
- **Telegram Bots:** mhive (@mm11homebot), percy (@mhivepolybot), bookworm (@mmhivepublisherbot)
- **1Password vault:** "OpenClaw" on `my.1password.com`
- **Google Workspace:** `mhive@bigbraincap.com` via `gog` CLI

---

## Completed

- [x] **Install gh CLI on Mac** — Homebrew + gh installed and authenticated as `mmaghsoodnia` *(2026-02-22)*
- [x] **Clone openclaw fork to Mac** — `~/openclaw` *(2026-02-22)*
- [x] **Set up SSH to VPS from Mac** — Generated ed25519 key, added to `root@100.71.224.113` *(2026-02-22)*
- [x] **Fix maple-proxy unhealthy status** — Restarted container; health check is a cosmetic issue in upstream image (checks port 8080 inside container but service runs on 3000). Proxy itself responds 200. *(2026-02-22)*
- [x] **Update OpenClaw on VPS** — CLI updated from `2026.2.15` → `2026.2.21-2`, Docker image rebuilt from fork code *(2026-02-22)*
- [x] **Fix VPS git remotes** — Changed `origin` from upstream to `mmaghsoodnia/openclaw`, kept upstream as `upstream`. VPS now pulls from our fork only. *(2026-02-22)*
- [x] **Sync VPS with fork** — Pulled latest from `origin/main`, rebuilt Docker image, restarted gateway. All 3 Telegram bots running, heartbeat active. *(2026-02-22)*
- [x] **Fix missing memory files** — Created `/root/.openclaw/workspace/hive-risk/memory/2026-02-22.md` and `/root/.openclaw/workspace/memory/heartbeat-state.json` *(2026-02-22)*
- [x] **Move confidential keys to 1Password vault "openclaw"** — All API keys migrated. ElevenLabs Talk API key added. *(2026-02-22)*
- [x] **Install 1Password CLI on Mac and VPS** — `op` v2.32.1 on both machines. Mac uses desktop app integration, VPS needs service account token setup. *(2026-02-22)*
- [x] **Install gog CLI (built from source)** — Security audit passed. Built from source (v0.11.0) on VPS. Installed via Homebrew on Mac. *(2026-02-22)*
- [x] **Authenticate gog for mhive@bigbraincap.com** — OAuth completed on Mac with Gmail, Calendar, Drive, Contacts, Docs, Sheets scopes. *(2026-02-22)*

---

## TODO

### High Priority

- [ ] **Rotate exposed secrets** — The following keys were inadvertently exposed in a Claude Code session context and should be rotated immediately:
  - ElevenLabs Talk API Key (regenerate in ElevenLabs dashboard, update 1Password + VPS)
  - Google OAuth client secret (rotate in Google Cloud Console project 619803175505, update 1Password)
- [ ] **Enable remaining Google APIs** — Calendar, Contacts (People API), Sheets, and Docs APIs need to be enabled in Google Cloud project `619803175505`. Gmail and Drive confirmed working.
- [ ] **Verify Google services access for agents** — After enabling APIs, test all 6 services (Gmail, Calendar, Drive, Contacts, Docs, Sheets) end-to-end from gog CLI.
- [ ] **Copy gog OAuth credentials to VPS** — Auth tokens are on Mac only. Need to copy `~/.config/gog/` (or equivalent) to VPS and make accessible inside Docker container.
- [ ] **Set up 1Password service account for VPS** — Create service account token in 1Password so `op` works headlessly on VPS for runtime secret injection.

### Medium Priority

- [ ] **Find or create push-to-VPS deploy script** — Check studio for existing script. If not found, create one in `mhive-ops` that does: push to GitHub → SSH to VPS → pull from fork → rebuild Docker → restart gateway.
- [ ] **Update `mhive-ops/approve-device.sh`** — IP is hardcoded to old address `76.13.79.239`, needs to be updated to Tailscale IP `100.71.224.113`.

### Low Priority

- [ ] **Fix maple-proxy health check** — The upstream `ghcr.io/opensecretcloud/maple-proxy:latest` image has a health check that curls `localhost:8080` but the service listens on port 3000. Consider overriding the health check in `docker-compose.yml` or opening an issue upstream.

---

## Notes

- **Deployment flow:** Mac/Studio → push to `mmaghsoodnia/openclaw` on GitHub → VPS pulls from `origin` (our fork) → rebuild Docker → restart gateway. Never pull upstream directly on VPS.
- **Agent system (The Hive):** 14 agents configured — main + 8 PolyHive agents + 5 BookHive agents. Primary model: `xai/grok-4-1-fast`.
- **VPS specs:** 31 GB RAM, 387 GB disk (5% used), 4 days uptime as of 2026-02-22.
- **Security incident (2026-02-22):** ElevenLabs API key and Google OAuth client_id/secret were exposed in Claude Code context. Keys should be rotated. This led to the security rule at the top of this file.
