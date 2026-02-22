# OpenClaw Operations TODO

> **Purpose:** This file tracks operational tasks, infrastructure changes, and project work for the mmaghsoodnia/openclaw fork. It is checked into GitHub so that any machine (Mac, Studio, VPS) pulling this repo has a shared, up-to-date view of what has been done and what remains. **All Claude Code sessions should read this file at the start of work, update it as tasks are completed, and commit changes back.** This ensures continuity across devices and sessions.

---

## Environment

- **VPS:** Tailscale IP `100.71.224.113` (user: `root`, project: `/root/openclaw`)
- **GitHub Fork:** `mmaghsoodnia/openclaw` (upstream: `openclaw/openclaw`)
- **VPS Docker Compose:** `/root/openclaw/docker-compose.yml`
- **VPS OpenClaw State:** `/root/.openclaw/`
- **Agents config:** `/root/.openclaw/openclaw.json`
- **Telegram Bots:** mhive (@mm11homebot), percy (@mhivepolybot), bookworm (@mmhivepublisherbot)

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

---

## TODO

### High Priority

- [ ] **Move confidential keys to 1Password vault "openclaw"** — Migrate all API keys, tokens, and secrets from `.env` and `openclaw.json` on VPS to 1Password. Update agent configs to pull from vault at runtime.
- [ ] **Verify Google services access for agents** — Confirm agents have full access to Google Drive, Sheets, Email, and Docs on `mhive@bigbraincap.com`. Test read/write from within agent sessions.

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
