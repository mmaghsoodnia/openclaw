# LLM Benchmark Results — 2026-03-13

**Run at:** 2026-03-13T14:56:00Z + 2026-03-13T15:20:38Z (Anthropic re-run) + 2026-03-13T20:10:46Z (Opus 4.6)
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
| claude-opus-4-6      | 56.0s / $0.246 | 39.0s / $0.187 | 35.7s / $0.159 | 43.6s       | $0.592     |
| deepseek-reasoner    | 60.6s / ERR    | 98.3s / $0.006 | 99.3s / $0.005 | 86.1s       | $0.011     |

### Key Findings — Latency

1. **Gemini Flash is 4-10x faster than everything else** — 9s avg vs 16-86s
2. **GPT-4o is the fastest premium model** — 16s avg, solid middle ground
3. **DeepSeek is catastrophically slow** — 69-86s avg, hitting VPS timeouts
4. **Claude is slower than expected** — 37-44s avg from VPS (Opus 43.6s, Sonnet 40.5s)
5. **Grok Fast is fast but not the fastest** — 22s avg, good for the price

### Key Findings — Cost

1. **Gemini Flash: $0.002 total** — absurdly cheap, 50x cheaper than Claude
2. **Grok Fast: $0.003 total** — nearly as cheap as Gemini
3. **DeepSeek Chat: $0.007** — cheap but the latency negates the cost savings
4. **GPT-4o: $0.042** — 20x more expensive than Gemini for similar latency
5. **Claude Sonnet: $0.10-0.12** — expensive but justified by quality
6. **Claude Opus: $0.59** — 5x Sonnet cost for same 4.7 score. Not justified unless higher token limits

### Note on DeepSeek Reasoner coordination test

The coordination test returned 0 input/output tokens, suggesting the response may have been malformed or timed out partially. The raw response should be checked.

## Quality Scores (manual review — 1 to 5)

| Model             | Coordination | Analysis | Execution | Overall | Notes                                                                 |
| ----------------- | ------------ | -------- | --------- | ------- | --------------------------------------------------------------------- |
| claude-opus-4-6   | 5            | 5        | 4         | 4.7     | Deepest reasoning, meta-pattern detection. Truncated execution (4/6)  |
| claude-sonnet-4-6 | 4            | 5        | 5         | 4.7     | Best value premium. Caught key error hex analysis, perfect PSG math   |
| claude-sonnet-4-5 | 4            | 4        | 5         | 4.3     | Very strong. Minor EV notation issue in analysis                      |
| grok-4-1-fast     | 3            | 3        | 3         | 3.0     | Solid middle. Best context usage among non-Claude models              |
| deepseek-chat     | 2            | 4        | 2         | 2.7     | Good analysis but no critical thinking, fabricated APIs               |
| gemini-2.0-flash  | 2            | 1        | 1         | 1.3     | Fast but wrong — fell for Chelsea EV trap, fabricated everything      |
| gpt-4o            | 1            | 1        | 1         | 1.0     | Weakest. Invalid JSON, vague, fully fabricated APIs                   |
| deepseek-reasoner | 0            | 1        | 1         | 0.7     | Total failure — reasoning chain consumed all tokens, zero output      |

_Reviewed 2026-03-13. See raw/ for full responses._

### Key Findings — Quality

1. **Claude Opus 4.6 ties Sonnet 4.6 at 4.7/5** — deepest reasoning and meta-pattern detection, but truncated by 2048 token limit. Would likely score 5.0 with more output budget.
2. **Claude Sonnet 4.6 is the best value premium (4.7/5)** — caught key error, perfect math, honest about uncertainty. 5x cheaper than Opus for same overall score.
3. **Claude Sonnet 4.5 is very close (4.3/5)** — minor math notation issue but excellent critical thinking and honesty
3. **Grok Fast is the best value (3.0/5)** — decent quality at $0.003 and 22s. Best non-Claude context usage
5. **Gemini Flash quality is terrible (1.3/5)** — fell for the Chelsea EV trap, fabricated APIs without admitting it. Speed without correctness is worthless
5. **GPT-4o surprised to the downside (1.0/5)** — invalid JSON, vague coaching, fabricated everything. Worst quality/price ratio
6. **DeepSeek Reasoner is unusable (0.7/5)** — 2048 max_tokens is not enough for its reasoning chain; zero content delivered

### Combined Ranking (Quality × Speed × Cost)

| Model             | Quality | Latency | Cost   | Verdict                                                    |
| ----------------- | ------- | ------- | ------ | ---------------------------------------------------------- |
| claude-opus-4-6   | 4.7     | 43.6s   | $0.592 | Highest ceiling but 5x cost of Sonnet for same score       |
| claude-sonnet-4-6 | 4.7     | 40.5s   | $0.117 | Best value premium — Planners primary (quality + cost)     |
| grok-4-1-fast     | 3.0     | 22.2s   | $0.003 | Best for Researchers/Doers (good value, decent quality)    |
| claude-sonnet-4-5 | 4.3     | 37.5s   | $0.105 | Strong fallback for Planners                               |
| deepseek-chat     | 2.7     | 69.4s   | $0.007 | Too slow from VPS despite decent analysis                  |
| gemini-2.0-flash  | 1.3     | 9.0s    | $0.002 | Speed-only fallback, not trustworthy as primary            |
| gpt-4o            | 1.0     | 16.3s   | $0.042 | Not recommended — poor quality for the price               |
| deepseek-reasoner | 0.7     | 86.1s   | $0.011 | Not recommended — unusable at 2048 tokens                  |

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
