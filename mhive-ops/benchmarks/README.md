# LLM Benchmark Framework

Test LLMs against real agent workloads before assigning them to agents. Produces timestamped, version-controlled results.

## Quick Start

```bash
# On VPS (requires API keys in /root/openclaw/.env)
ssh root@100.71.224.113
cd /root/openclaw
bash mhive-ops/benchmarks/run-benchmark.sh
```

## What It Tests

3 prompts matching our agent categories, using real mhive workspace files as context:

| Test         | Category   | Context Size                      | What It Measures                              |
| ------------ | ---------- | --------------------------------- | --------------------------------------------- |
| coordination | Planner    | ~20KB (SOUL+MEMORY+HEURISTICS)    | Strategic reasoning, prioritization, coaching |
| analysis     | Researcher | ~13KB (SOUL+MEMORY) + market data | Math accuracy, EV/Kelly calc, JSON output     |
| execution    | Doer       | ~5KB (minimal)                    | API accuracy, step completeness, honesty      |

## Filtering

```bash
# Test specific models only
bash mhive-ops/benchmarks/run-benchmark.sh --models deepseek-reasoner,claude-sonnet-4-6-20250514

# Test specific prompts only
bash mhive-ops/benchmarks/run-benchmark.sh --prompts coordination,analysis

# Combine
bash mhive-ops/benchmarks/run-benchmark.sh --models gemini-2.0-flash --prompts coordination
```

## Adding a New Model

1. Add entry to `models.json`
2. Add model to the `MODEL_*` arrays in `run-benchmark.sh`
3. Ensure the API key env var is set in `.env`
4. Run benchmark

## Results Structure

```
results/
└── YYYY-MM-DD/
    ├── summary.md      # Comparison table (timing + quality scores)
    ├── timing.csv      # Machine-readable: model,prompt,latency,tokens,cost
    └── raw/            # Full API responses (evidence archive)
        ├── deepseek-reasoner_coordination.json
        ├── claude-sonnet-4-6_analysis.json
        └── ...
```

## Quality Scoring

After each run, review `raw/` responses and fill in the quality scores (1-5) in `summary.md`. Criteria are documented in each prompt file under `## Scoring Criteria`.

## History

Results accumulate by date. Compare across runs to track:

- Model improvements over time
- New model performance vs baselines
- Regression detection after provider updates
