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
- **Telegram Bots:** mhivemain (@mhivemainbot), mhivepoly (@mhivepolybot), mhivebook (@mhivebookbot), mhivebrand (@mhivebrandbot, disabled), mhivedoost (@mhivedoostbot)
- **1Password vault:** "OpenClaw" on `my.1password.com`
- **1Password on VPS:** Service account token at `/root/.op-service-account-token`, loaded via `.bashrc` and `.profile`
- **Google Workspace:** `mhive@bigbraincap.com` via `gog` CLI (file keyring, password from 1Password)
- **gog on VPS:** Binary at `/usr/local/bin/gog` (built from source v0.11.0), config at `/root/.config/gogcli/`, mounted into container via override

---

## Completed

<details>
<summary>Infrastructure setup — Feb 22–27 (click to expand)</summary>

- [x] Install gh CLI, clone fork, SSH to VPS, fix maple-proxy, update OpenClaw, fix git remotes _(2026-02-22)_
- [x] Move keys to 1Password (13 items), install op CLI on Mac+VPS, set up service account _(2026-02-22)_
- [x] Install gog from source (v0.11.0), set up file keyring + 1Password, authenticate, enable Google APIs, copy to VPS+Docker _(2026-02-22)_
- [x] Add secrets handling rules, create deploy script, fix maple-proxy health check _(2026-02-22)_
- [x] Move project to `~/Projects/openclaw/`, install Node.js+pnpm, verify local build _(2026-02-22)_
- [x] Fix PolyHive betting (venv 3.14→3.11 rebuild, Polymarket creds to 1Password) _(2026-02-23)_
- [x] Rotate ElevenLabs + Google OAuth keys _(2026-02-24)_
- [x] Make Python venv persistent in Docker (Dockerfile + startup wrapper) _(2026-02-24)_
- [x] Disable WhatsApp (unsolicited pairing messages), set up local staging, merge upstream _(2026-02-25)_
- [x] Zero hardcoded secrets — all 14 agents use env var fallback from 1Password _(2026-02-27)_

</details>

<details>
<summary>Platform & agent ops — Mar 3–13 (click to expand)</summary>

- [x] Set up desktop gog MCP service, fix staging gog binary (linux/arm64) + credentials _(2026-03-03)_
- [x] Fix Telegram bots (re-enable plugin+channel), add emergency cost kill switch to all 14 TOOLS.md _(2026-03-04)_
- [x] Merge upstream v2026.3.2 + deploy (1600 commits, Dockerfile preserved) _(2026-03-06)_
- [x] Fix PolyHive Phase 1 — 6 root causes, 7 RUNBOOKs written, 8 TOOLS.md updated, model assignments corrected _(2026-03-07)_
- [x] Implement PolyHive audit system — auditor RUNBOOK rewrite, daily KPI audit cron, PM morning gate _(2026-03-10)_
- [x] Merge upstream v2026.3.11-beta.1 + deploy (Dockerfile→build arg migration) _(2026-03-12)_
- [x] Merge upstream to latest + deploy (501 commits, all bots running) _(2026-03-13)_

</details>

- [x] **Upgrade mhive programming — health monitoring + authority model** — Diagnosed Scout as example of persistent agent failure (6 root causes: model churn, weak models, no RUNBOOK, broken venv, memory chaos, comms failures). Key insight: Scout doesn't need to be an agent — it's a script wrapper. Built `hive-health.py` diagnostic tool. Updated 8 workspace files on both staging and VPS: HEARTBEAT (Priority 0: health review every other day), SOUL (lifecycle v2026-03-14: role audit + health monitoring steps), MEMORY (3 lessons), HEURISTICS (2 anti-patterns), SCORECARD-TEMPLATE (role audit gate + health tracking), AGENTS (bootstrap checklist), TOOLS (health script docs), RESTRUCTURE.md (new — MM approval template). Defined mhive's authority: can fix models/RUNBOOKs/memory/cron directly; structural changes need MM approval via RESTRUCTURE.md. Fixed mhive's corrupted session (tool*use without tool_result). Cleaned 5 stale workspace files on VPS. *(2026-03-14)\_
- [x] **Verify mhive delegated work + agent cleanup** — Audited mhive's Mar 14-15 output. Scout removed from config (instructed mhive directly), memory cleanup done, BookHive RUNBOOKs written, inter-agent comms confirmed working. Removed 4 ghost agent dirs on VPS (hive-scout, hive-trader, hive-auditor, relo-pm). Agent count: 14 → 11. _(2026-03-16)_
- [x] **Merge upstream v2026.3.14 + deploy** — Merged 989 upstream commits (clean, no conflicts). Android fixes, browser non-Chrome profiles, Telegram health check proxy, Slack bolt interop, Plugin SDK refactors. Built, pushed, deployed to VPS + staging. _(2026-03-16)_
- [x] **Fix plugin runtime regression** — Upstream merge introduced `resolvePluginRuntimeModulePath()` which looks for `dist/plugins/runtime/index.js`, but the build config never emitted it as a separate entry. All agent turns failed in Docker with "Unable to resolve plugin runtime module." Fixed by adding `src/plugins/runtime/index.ts` as a standalone build entry in `tsdown.config.ts`. Deployed to both VPS and staging — zero errors. _(2026-03-16)_
- [x] **Deep clean removed agent artifacts** — Removed workspace dirs for hive-scout (95MB), hive-trader (980KB), hive-auditor (93MB). Purged all stale references from 10+ workspace files (TOOLS.md, RUNBOOK.md, SOUL.md across 6 agents). Updated market scanner cron to write to `the-hive/data/market-scans/`. Deleted obsolete `CRON-JOBS.md`, `AGENT_DEV_PLANS.md`, `WORKFLOW.md`, `SCORECARD.md`. Regenerated `HEALTH.md`. Deleted stale gateway logs (3MB, from Feb 15). _(2026-03-17)_
- [x] **Fix bookworm Telegram group** — Book PM bot not responding in "Book group". Root cause: mhive added group chat ID (`-5119732747`) to `allowFrom` instead of `groups` config. `allowFrom` only accepts user IDs — group IDs are silently rejected. Also needed `requireMention: false`. Fixed config, documented in mhive's TOOLS.md for future reference. _(2026-03-17)_
- [x] **LLM benchmark framework + model matrix** — Built benchmark tool (8 models x 3 prompts = 24 tests). Scored quality: Claude Sonnet 4.6 (4.7/5), Grok Fast (3.0/5), Gemini Flash (1.3/5). Rolled back VPS from DeepSeek (cascading timeouts) to stable US models. Split benchmark into standalone project at `~/Projects/llm-bench/` (separate agent manages it). _(2026-03-13 — 2026-03-20)_
- [x] **Add Groq API key to all environments** — Added `GROQ_API_KEY` to `.env.vps.tpl`, `.env.staging.tpl`, `docker-compose.staging.yml`, and VPS `docker-compose.override.yml`. Also backfilled `VENICE_API_KEY` and `DEEPSEEK_API_KEY` that were missing from staging config. Verified key live in VPS container. _(2026-03-22)_
- [x] **Merge upstream + deploy** — Merged 1,329 upstream commits (one conflict in `tsdown.config.ts` — our plugin runtime fix now upstream, resolved cleanly). Key changes: per-agent defaults (#51974, optional `thinkingDefault`/`reasoningDefault`/`fastModeDefault`), Discord message dedup, startup perf, plugin resolver cache fix. Built, tested staging, deployed to VPS. All Telegram bots connected. _(2026-03-22)_
- [x] **Mhive OS v2 — Fractal operating system overhaul** — Redesigned mhive from IT ops manager to operator of operators. Fractal model: same OS at two levels (PMs operate teams, mhive operates PMs). Installed PM OS into Percy and Book PM (SCORECARD.md, OPEN.md, BACKLOG.md, enhanced MORNING*PROTOCOL). Rewrote mhive SOUL.md (capital allocator identity), HEARTBEAT.md (verify/pulse/review cadence), trimmed MEMORY.md. Created VERIFICATION-MAP.md for ground truth cross-referencing. Created reusable PM OS templates (`templates/pm-os/`). Added team-building playbook to HEURISTICS.md. Backup at `/root/workspace-backup-2026-03-22.tar.gz`. Week 4 decision point: 2026-04-19. *(2026-03-22)\_
- [x] **Merge upstream v2026.3.25-dev + deploy** — Merged ~1,355 upstream commits in two passes (2026.3.14 → 2026.3.25-dev, clean merges, no conflicts). Key: Telegram forum topic routing, photo preflight, 403 error handling, DM auth for callbacks, Discord crash prevention, channel startup isolation, SQLite memory perf, 20+ security fixes (path traversal, .env filtering, scope-upgrade blocking, webhook signature validation, admin scope gates, HTTP session ownership, least-privilege plugin scopes). New: Microsoft Foundry provider, video gen infra, OpenAI-compat endpoints. Breaking: ClawHub plugin installs preferred over npm (low risk). _(2026-03-26)_
- [x] **Merge upstream v2026.3.28 + deploy** — Merged 29 upstream commits. Key changes: Slack status reactions, LINE ACP support, plugin `requireApproval` hook, sub-agent memory tools, gateway auth fix, Telegram stream-order fix, web search cache fix, LanceDB memory fix, Node 24 in Docker. **Breaking:** Bundled plugin loading refactored from static imports to runtime filesystem scanning + jiti transpilation. Docker images need `OPENCLAW_BUNDLED_PLUGINS_DIR=/app/dist/extensions` (pointing to compiled `.js`, not source `.ts`) or the gateway hangs at 100% CPU indefinitely. Applied fix to both VPS and staging `docker-compose` overrides. Security audit of all 29 commits: clean. _(2026-03-29)_
- [x] **Merge upstream v2026.4.1 + deploy** — Merged 964 upstream commits (v2026.3.28 → v2026.4.1). Security audit: all clean. Key changes: SearXNG web search provider, exec approval system (Discord/Telegram/webchat), major security hardening (exec/spawn/shell denied by default via HTTP, trusted-proxy origin checks, session revocation on token rotation, sandbox env sanitized, auth env vars blocked from workspace dotenv), configurable chat history max chars, memory session indexing fix, bundled channel plugin compat fix, node pairing reconciliation refactor, Matrix E2EE crypto-wasm. New deps: `@matrix-org/matrix-sdk-crypto-wasm`. Removed: `@aws-sdk/client-bedrock`. `OPENCLAW_BUNDLED_PLUGINS_DIR=/app/dist/extensions` workaround still required. Internal hooks now enabled by default. _(2026-04-01)_

---

## TODO

> **Architecture note:** Before working on any item below, read `mhive-ops/ARCHITECTURE.md`.
> Every item is tagged **[Layer 1 — Operator]** or **[Layer 2 — Agent]** so you know the
> correct approach without re-deriving it.

### High Priority

- [x] **Update VPS to latest fork** — `[Layer 1 — Operator]` _(2026-02-25)_
  - Pulled merged code on VPS, rebuilt Docker image, restarted gateway. All 3 Telegram bots verified running.

- [x] **Back up VPS gog keyring tokens to 1Password** — `[Layer 1 — Operator]` _(2026-03-03)_
  - Stored base64-encoded OAuth refresh tokens in 1Password item "GOG OAuth Tokens" (fields: `default_token`, `account_token`).
  - Verified `setup-gog.sh` can reconstruct the full gogcli directory from 1Password.
  - Staging gog tested end-to-end: Gmail, Calendar, Drive all working from inside Docker container.

- [ ] **Set up staging on Mac Studio** — `[Layer 1 — Operator]` _(Assigned to Mac Studio Claude)_
  - Mac Studio does not have a local staging environment yet. Only the Mac (current dev machine) has one.
  - Replicate the setup from `mhive-ops/staging/` scripts. Needs Docker Desktop, 1Password service account token at `~/.op-service-account-token`, and a linux/arm64 gog binary at `~/.openclaw-staging/bin/gog`.
  - See `mhive-ops/sessions/2026-02-25.md` (staging setup) and `2026-03-03.md` (gog binary fix) for reference.

---

## Notes

- **Multi-machine setup:** This project is developed across Mac Studio (original build machine), Mac (second dev machine with staging), and VPS (production). Multiple Claude Code instances coordinate via this `TODO.md`, `mhive-ops/ARCHITECTURE.md`, and session logs in `mhive-ops/sessions/`. Each machine's Claude Code also has its own auto-memory (`MEMORY.md`) for machine-specific knowledge.
- **Pre-task workspace sync (MANDATORY):** Before starting any task involving staging, sync the agent workspace from VPS: `bash mhive-ops/staging/sync-workspace.sh`. This pulls the latest agent memory, soul, and session data so staging tests run against current agent state. Done automatically by `start.sh` and `rebuild.sh`. Falls back to existing files if VPS is unreachable.
- **Architecture reference:** Full system architecture (two-layer model, context window construction, change ownership table) documented in `mhive-ops/ARCHITECTURE.md`. Read before making changes.
- **Deployment flow:** Mac/Studio → push to `mmaghsoodnia/openclaw` on GitHub → VPS pulls from `origin` (our fork) → rebuild Docker → restart gateway. Never pull upstream directly on VPS.
- **Agent system (The Hive):** 11 agents configured — main (mhive) + 4 PolyHive + 1 PolyHive risk + 5 BookHive. Planners (mhive, Percy, risk, book-pm): `anthropic/claude-sonnet-4-6`, Researchers/Doers: `xai/grok-4-1-fast`. Scout replaced by cron-driven market scanner. Trader + Auditor replaced by Python scripts. relo-pm parked.
- **Mhive OS v2 (2026-03-22):** Fractal operating system. PMs (Percy, Book PM) own team scorecards, experiments, and backlogs — updated daily. Mhive verifies PM claims against ground truth (VERIFICATION-MAP.md), grades PMs weekly on output + accuracy, adjusts token budget based on verified results. Daily 2-line pulse to MM + Friday weekly review. Escalation ladder: coach → investigate → escalate to MM. PM OS templates at `workspace/templates/pm-os/` for future teams. Backup: `/root/workspace-backup-2026-03-22.tar.gz`. Week 4 assessment: 2026-04-19.
- **Local dev (Mac):** Project at `~/Projects/openclaw/`, Node.js 22.22.0 (`/opt/homebrew/opt/node@22/bin`), pnpm 10.23.0 via corepack.
- **VPS specs:** 31 GB RAM, 387 GB disk (5% used), 4 days uptime as of 2026-02-22.
- **Docker override on VPS:** `/root/openclaw/docker-compose.override.yml` mounts gog binary/config, LLM benchmark results (`/data/llm-bench-results`), and passes all secrets from `.env` (generated by `op inject` from `mhive-ops/.env.vps.tpl`). See `mhive-ops/ARCHITECTURE.md` § "Docker volume mounts" for full mount table.
- **Secrets:** Zero hardcoded keys. All secrets in 1Password vault "OpenClaw", injected via `op inject` into Docker env vars. See `mhive-ops/ARCHITECTURE.md` for details.
- **Security incident (2026-02-22):** ElevenLabs API key and Google OAuth client_id/secret were exposed in Claude Code context. Keys rotated (2026-02-24). This led to the security rule at the top of this file.
- **Polymarket 1Password items (2026-02-23):** "Polymarket Wallet" (private_key, funder_address, chain_id, signature_type) and "Polymarket API" (host, gamma_api_base_url). `.env.tpl` on VPS at `/root/.openclaw/workspace/the-hive/.env.tpl` — regenerate `.env` via `op inject --account my.1password.com -i .env.tpl -o .env`.
- **Python venv persistent (2026-02-24):** The venv at `/root/.openclaw/workspace/the-hive/venv/` is on a Docker volume mount and auto-bootstrapped at container start via `docker-compose.override.yml`. `python3-pip` and `python3-venv` are in the Dockerfile.
- **Pre-existing Polymarket notes (2026-02-23):** Wallet address and funder address don't match (may indicate proxy/safe setup). Wallet has ~$200 USDC balance. The address mismatch was not caused by the VPS migration.
- **Emergency kill switch (2026-03-04):** Two-lever kill: `cron.enabled=false` + `agents.defaults.heartbeat.every=""`. Channels/Telegram stay ON. Documented in all 14 TOOLS.md on VPS + ARCHITECTURE.md. Trigger to mhive: "Emergency stop — kill the spending". Resume: "Resume normal operations". Never disable channels — that cuts communication.
- **Telegram plugin vs channel (2026-03-04):** The Telegram channel has TWO independent on/off switches: `channels.telegram.enabled` (channel config) AND `plugins.entries.telegram.enabled` (plugin registry). Both must be true for bots to start. The plugin being disabled (`false`) silently prevents all bots from connecting with no error logs.
- **OPENCLAW_BUNDLED_PLUGINS_DIR fix (2026-03-29):** Upstream v2026.3.28 refactored plugin loading to use runtime filesystem scanning + jiti TypeScript transpilation instead of pre-generated static imports. The Dockerfile sets `OPENCLAW_BUNDLED_PLUGINS_DIR=/app/extensions` (source `.ts` files), but the new code tries to jiti-transpile all 13+ channel plugins synchronously at startup, blocking the main thread at 100% CPU with no logs and no HTTP port. **Fix:** Set `OPENCLAW_BUNDLED_PLUGINS_DIR=/app/dist/extensions` in docker-compose overrides (both VPS and staging) to point to the pre-compiled `.js` files. This env var must be maintained in future upgrades until upstream fixes the Dockerfile default.
