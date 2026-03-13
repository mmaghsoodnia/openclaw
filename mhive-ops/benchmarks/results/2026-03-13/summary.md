# LLM Benchmark Results — 2026-03-13

**Run at:** 2026-03-13T14:56:00Z + 2026-03-13T15:20:38Z (Anthropic re-run after model ID fix)
**Workspace context:** 20,304 bytes (planner), 12,629 bytes (researcher), 183 bytes (doer)
**Max tokens:** 2048
**Timeout:** 120s per call

## Timing & Cost

| Model                | Coordination   | Analysis       | Execution      | Avg Latency | Total Cost |
| -------------------- | -------------- | -------------- | -------------- | ----------- | ---------- |
| **gemini-2.0-flash** | 14.0s / $0.001 | 5.5s / $0.001  | 7.6s / $0.000  | **9.0s**    | **$0.002** |
| gpt-4o               | 21.6s / $0.021 | 10.4s / $0.013 | 16.9s / $0.007 | 16.3s       | $0.042     |
| grok-4-1-fast        | 23.0s / $0.002 | 19.5s / $0.001 | 24.2s / $0.001 | 22.2s       | $0.003     |
| deepseek-chat        | 80.1s / $0.003 | 32.8s / $0.002 | 95.2s / $0.002 | 69.4s       | $0.007     |
| claude-sonnet-4-5    | 53.2s / $0.049 | 31.4s / $0.032 | 27.8s / $0.023 | 37.5s       | $0.105     |
| claude-sonnet-4-6    | 54.3s / $0.049 | 32.5s / $0.036 | 34.5s / $0.032 | 40.5s       | $0.117     |
| deepseek-reasoner    | 60.6s / ERR    | 98.3s / $0.006 | 99.3s / $0.005 | 86.1s       | $0.011     |

### Key Findings — Latency

1. **Gemini Flash is 4-10x faster than everything else** — 9s avg vs 16-86s
2. **GPT-4o is the fastest premium model** — 16s avg, solid middle ground
3. **DeepSeek is catastrophically slow** — 69-86s avg, hitting VPS timeouts
4. **Claude is slower than expected** — 37-40s avg from VPS (likely distance to Anthropic API)
5. **Grok Fast is fast but not the fastest** — 22s avg, good for the price

### Key Findings — Cost

1. **Gemini Flash: $0.002 total** — absurdly cheap, 50x cheaper than Claude
2. **Grok Fast: $0.003 total** — nearly as cheap as Gemini
3. **DeepSeek Chat: $0.007** — cheap but the latency negates the cost savings
4. **GPT-4o: $0.042** — 20x more expensive than Gemini for similar latency
5. **Claude (both): $0.10-0.12** — by far the most expensive

### Note on DeepSeek Reasoner coordination test

The coordination test returned 0 input/output tokens, suggesting the response may have been malformed or timed out partially. The raw response should be checked.

## Quality Scores (manual review — 1 to 5)

| Model             | Coordination | Analysis | Execution | Overall | Notes |
| ----------------- | ------------ | -------- | --------- | ------- | ----- |
| deepseek-reasoner |              |          |           |         |       |
| deepseek-chat     |              |          |           |         |       |
| claude-sonnet-4-6 |              |          |           |         |       |
| claude-sonnet-4-5 |              |          |           |         |       |
| gpt-4o            |              |          |           |         |       |
| gemini-2.0-flash  |              |          |           |         |       |
| grok-4-1-fast     |              |          |           |         |       |

_Review raw responses in `raw/` directory and fill in scores above._

## Scoring Criteria

### Coordination (Planner)

1. Prioritization — correct root cause identification
2. Critical thinking — questions unverified claims
3. Coaching quality — specific, not generic
4. Context usage — references workspace files
5. Judgment — correct escalation decisions

### Analysis (Researcher)

1. Math accuracy — EV and Kelly calculations
2. Correct identification — PSG as highest EV
3. JSON quality — valid structured output
4. Risk awareness — flags Barcelona negative EV
5. Practical judgment — respects bankroll limits

### Execution (Doer)

1. API accuracy — real vs fabricated endpoints
2. Step completeness — all 6 steps covered
3. Error handling — failure scenarios
4. Safety — parameter verification
5. Honesty — admits uncertainty vs invents
