# OpenClaw Project — Claude Code Rules

## CRITICAL — Secrets Handling

**NEVER read, display, or pull secret values (API keys, tokens, passwords, credentials) into the conversation context.** All conversation content transits Anthropic's API servers. Exposing secrets in the context window means they leave the local machine.

**Safe patterns — always use these:**
- `op read "op://OpenClaw/ItemName/field"` piped directly into target commands/files
- `op inject` to template secrets into config files without exposing values
- `op run` to inject secrets as environment variables into a subprocess
- Write secrets from `op` to target files in a single pipeline — never store in shell variables, never echo to stdout

**If a user asks to read, move, or set a secret:** explain this rule and use the safe patterns above. Never use `op item get` with visible output. Never `cat`, `echo`, or print credentials.

## CRITICAL — Third-Party Binaries

**Never download or install pre-built binaries.** Always:
1. Clone the source repository
2. Run a security audit on the code (check dependencies, network calls, build scripts)
3. Build from source
4. Verify the build output

## Session Logs

**At the end of every session, write a session log to `mhive-ops/sessions/YYYY-MM-DD.md`.** If multiple sessions happen on the same day, append a suffix (e.g., `2026-02-23-2.md`). The log should summarize what was done, what files were created/modified, and what remains. This is how future sessions (on any machine, by any LLM) catch up on history. Read existing session logs in `mhive-ops/sessions/` for context when starting work.

## Project Context

- **Read `TODO.md` at the project root at the start of every session.** It contains the current task list, environment details, deployment flow, and security notes. Update it as work progresses and commit regularly.
- **Read session logs in `mhive-ops/sessions/`** for detailed history of past work. Write a new session log at the end of each session.
- **1Password vault:** "OpenClaw" on `my.1password.com` (use `--account my.1password.com` when multiple accounts exist)
- **VPS:** Tailscale IP `100.71.224.113`, user `root`, project at `/root/openclaw`
- **GitHub Fork:** `mmaghsoodnia/openclaw` — VPS pulls from this fork, not upstream
- **Deployment flow:** Mac/Studio → push to fork → VPS pulls from `origin` → rebuild Docker → restart gateway
- **Google Workspace:** `mhive@bigbraincap.com` via `gog` CLI
- **Agent system:** "The Hive" — 14 agents. See `openclaw.json` on VPS for full config.
