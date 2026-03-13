# Test 1: COORDINATION (Planner Task)

## System Context Files

- SOUL.md
- MEMORY.md
- HEURISTICS.md

## System Prompt Prefix

You are Mhive, the Hive Architect & Manager. You design, bootstrap, coach, and hold accountable autonomous agent teams. Your workspace files are provided below as context.

## User Prompt

Percy (hive-pm) just sent this status update:

"Daily Pipeline Report — 2026-03-13 06:00 UTC

1. Scout: Completed scan of 124 Polymarket events. Found 4 high-confidence soccer opportunities (EV > 15%). Data ready for Analyst.
2. Analyst: NO RESPONSE for 6 hours. Last activity 2026-03-12 23:45 UTC. Sessions_send to analyst timed out 3 times.
3. Risk: Cron job failing with 'FailoverError: LLM request timed out' — last 4 cycles failed. Cannot approve pending trades.
4. Trader: $135 USDC in wallet. Reports 'private key validation error: expected 32 bytes, got 26 bytes'. Cannot execute approved trades.
5. Contrarian/Quant: Idle — waiting on Analyst thesis to review.

Pipeline status: BLOCKED. Zero trades executed in 72 hours.
Recommendation: Need MM to restart gateway and fix Trader env."

Meanwhile, BookHive PM has been completely unresponsive for 8 hours despite 4 pings. Last known activity was working on Ch2 draft. Book Publisher reports Google Drive upload failing with permission error.

What are your top 3 priorities right now? For each priority: (a) what is the root cause, (b) what specific action do you take, (c) what do you tell the relevant PM, and (d) what do you escalate to MM? Be specific — reference your heuristics and coaching framework.

## Scoring Criteria (1-5 each)

1. **Prioritization** — Does it correctly identify that the LLM timeout cascade is the root cause blocking everything? (not "restart gateway" or "fix trader env")
2. **Critical Thinking** — Does it question the "private key 26 vs 32 bytes" error as possibly hallucinated/unverified? Does it recognize that Percy's recommendation may be wrong?
3. **Coaching Quality** — Is the response specific and actionable, not generic advice? Does it address each PM differently?
4. **Context Usage** — Does it reference HEURISTICS.md patterns, MEMORY.md history, or SOUL.md principles?
5. **Judgment** — Does it correctly decide what to escalate vs handle itself?
