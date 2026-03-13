# LLM Benchmark Framework

Test LLMs against real agent workloads before assigning them to production agents. Produces timestamped, version-controlled results that accumulate over time.

## Why This Exists

Agents make real decisions (trades, coordination, analysis). Model quality directly affects outcomes. We discovered that the cheapest/fastest model (Gemini Flash, 9s, $0.002) scores 1.3/5 on quality — it picked the wrong market, fabricated APIs, and never admitted uncertainty. Meanwhile the "slow expensive" model (Claude Sonnet 4.6, 40s, $0.12) scores 4.7/5. Speed without correctness is worthless.

This framework replaces ad-hoc model selection with measurable evidence.

## Quick Start

```bash
# On VPS (requires API keys in /root/openclaw/.env)
ssh root@100.71.224.113
cd /root/openclaw
bash mhive-ops/benchmarks/run-benchmark.sh
```

## What It Tests

3 prompts matching agent categories, using real mhive workspace files as system context:

| Test         | Category   | Context Size                      | What It Measures                              |
| ------------ | ---------- | --------------------------------- | --------------------------------------------- |
| coordination | Planner    | ~20KB (SOUL+MEMORY+HEURISTICS)    | Strategic reasoning, prioritization, coaching  |
| analysis     | Researcher | ~13KB (SOUL+MEMORY) + market data | Math accuracy, EV/Kelly calc, JSON output      |
| execution    | Doer       | ~5KB (minimal)                    | API accuracy, step completeness, honesty       |

Each prompt contains built-in traps to differentiate quality:
- **Coordination:** "private key 26 vs 32 bytes" — tests if model questions unverified claims
- **Analysis:** Chelsea vs PSG EV — tests if model picks the real highest-EV market (PSG, not Chelsea)
- **Execution:** Polymarket CLOB API — tests if model fabricates endpoints or admits uncertainty

## Filtering

```bash
# Test specific models only
bash mhive-ops/benchmarks/run-benchmark.sh --models claude-opus-4-6,grok-4-1-fast

# Test specific prompts only
bash mhive-ops/benchmarks/run-benchmark.sh --prompts coordination,analysis

# Combine
bash mhive-ops/benchmarks/run-benchmark.sh --models gemini-2.0-flash --prompts coordination
```

## Adding a New Model

1. Add entry to `models.json` (pricing reference)
2. Add model to the `MODEL_ENDPOINTS`, `MODEL_TYPES`, `MODEL_KEYS`, `MODEL_COST_IN/OUT` arrays and `ALL_MODELS` list in `run-benchmark.sh`
3. Add a row to the summary template table in `run-benchmark.sh`
4. Ensure the API key env var is set in `/root/openclaw/.env` on VPS
5. Run: `bash mhive-ops/benchmarks/run-benchmark.sh --models <new-model-id>`
6. Pull raw responses back and score quality (see Scoring section)

### Supported API types

The script handles three API formats automatically based on `MODEL_TYPES[model]`:
- `openai` — OpenAI-compatible (DeepSeek, xAI Grok, OpenAI, Venice)
- `anthropic` — Anthropic Messages API (Claude models)
- `google` — Google Gemini generateContent API

### Model ID discovery

Anthropic uses short model IDs (e.g., `claude-sonnet-4-6` not `claude-sonnet-4-6-20250514`). To discover valid IDs:
```bash
curl -s -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" \
  https://api.anthropic.com/v1/models | python3 -m json.tool | grep '"id"'
```

## Results Structure

```
results/
└── YYYY-MM-DD/
    ├── summary.md      # Comparison table (timing + quality scores)
    ├── timing.csv      # Machine-readable: model,prompt,latency_ms,input_tokens,output_tokens,cost_usd,timestamp
    └── raw/            # Full API responses (evidence archive)
        ├── deepseek-reasoner_coordination.json
        ├── claude-sonnet-4-6_analysis.json
        └── ...
```

Results accumulate by date. Each new run gets its own date directory. This enables:
- Comparing the same model across dates (did DeepSeek get faster?)
- Comparing a new model against historical baselines
- Justifying model assignments with evidence
- Detecting regressions after provider updates

## Quality Scoring (1-5 scale)

After running the benchmark, review each raw response in `raw/` and score it. Criteria are defined in each prompt file (`prompts/*.md`).

### How to score

For each raw response file:
1. Extract the model's response text:
   - OpenAI-compatible: `.choices[0].message.content`
   - Anthropic: `.content[0].text`
   - Google: `.candidates[0].content.parts[0].text`
2. Score on the 5 criteria for that prompt type (see below)
3. Record scores in `summary.md` quality table

### Scoring criteria summary

**Coordination (Planner):** prioritization, critical thinking (questions unverified claims), coaching quality, context usage (references workspace files), judgment (escalation decisions)

**Analysis (Researcher):** math accuracy (EV/Kelly), correct identification (PSG not Chelsea), JSON quality, risk awareness (Barcelona negative EV), practical judgment (respects bankroll limits)

**Execution (Doer):** API accuracy (real vs fabricated), step completeness (all 6 steps), error handling, safety (parameter verification), honesty (admits uncertainty vs invents)

### Scoring guidelines

- **5/5:** Exceptional. Catches all traps, uses deep context, admits uncertainty where appropriate
- **4/5:** Strong. Catches most traps, good specificity, minor issues
- **3/5:** Adequate. Gets the basics right but misses subtlety
- **2/5:** Weak. Misses key traps or fabricates without admitting it
- **1/5:** Poor. Wrong answers, fabricated content, no critical thinking
- **0/5:** Failure. No usable output (e.g., empty response, all tokens consumed by reasoning)

## Current Model Matrix (applied to VPS)

Based on the 2026-03-13 benchmark (8 models × 3 prompts):

| Category    | Agents                                                               | Primary                   | Fallback 1              | Fallback 2               |
| ----------- | -------------------------------------------------------------------- | ------------------------- | ----------------------- | ------------------------ |
| Planners    | mhive, hive-pm, hive-risk, book-pm                                  | anthropic/claude-sonnet-4-6 | xai/grok-4-1-fast      | google/gemini-2.0-flash  |
| Researchers | hive-scout, hive-analyst, hive-contrarian, hive-quant, hive-auditor, book-researcher, book-editor, book-marketing, relo-pm | xai/grok-4-1-fast | google/gemini-2.0-flash | deepseek/deepseek-chat   |
| Doers       | hive-trader, book-publisher                                          | xai/grok-4-1-fast         | google/gemini-2.0-flash | deepseek/deepseek-chat   |

**Rationale:** Planners need quality (4.7/5 at $0.12/call). Researchers/Doers need speed+value (3.0/5 at $0.003/call). DeepSeek is last-resort only (too slow from VPS: 69-86s avg).

## Workflow for Updating Model Assignments

1. Run benchmark with new/updated models
2. Score quality from raw responses
3. Compare against existing results in `results/`
4. Update `openclaw.json` on VPS via SSH (gateway hot-reloads, no restart needed)
5. Commit results to git and push

## Key Learnings (2026-03-13)

- DeepSeek Reasoner consumes all tokens in its reasoning chain at 2048 max_tokens — zero content delivered. Unusable without higher token limits.
- DeepSeek Chat from VPS→China averages 69-86s per call. Simple hello tests pass (4s) but real agent workloads with large context cause cascading timeouts.
- Gemini Flash is 4-10x faster than everything else but its quality is terrible (1.3/5) — it fell for every trap.
- Claude Opus 4.6 ties Sonnet 4.6 at 4.7/5 quality but costs 5x more ($0.59 vs $0.12). Not justified at current token limits.
- GPT-4o scored worst (1.0/5) — surprisingly poor for the price ($0.042). Invalid JSON, vague, fabricated everything.
