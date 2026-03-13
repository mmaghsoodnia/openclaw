#!/usr/bin/env bash
# LLM Benchmark Runner — Real Agent Workload Tests
# Runs on VPS (requires API keys in .env)
# Usage: bash mhive-ops/benchmarks/run-benchmark.sh [--models model1,model2] [--prompts 01,02]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="/root/.openclaw/workspace"
ENV_FILE="/root/openclaw/.env"
TODAY=$(date -u +%Y-%m-%d)
RESULTS_DIR="$SCRIPT_DIR/results/$TODAY"
RAW_DIR="$RESULTS_DIR/raw"
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MAX_TOKENS=2048
TIMEOUT=120  # seconds per API call

# Parse optional filters
FILTER_MODELS=""
FILTER_PROMPTS=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --models) FILTER_MODELS="$2"; shift 2 ;;
    --prompts) FILTER_PROMPTS="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Load env
if [[ -f "$ENV_FILE" ]]; then
  set -a; source "$ENV_FILE"; set +a
else
  echo "ERROR: $ENV_FILE not found"; exit 1
fi

mkdir -p "$RAW_DIR"

# --- Assemble system contexts from live workspace ---
echo "=== Assembling system contexts from workspace ==="

CONTEXT_PLANNER=""
for f in SOUL.md MEMORY.md HEURISTICS.md; do
  if [[ -f "$WORKSPACE/$f" ]]; then
    CONTEXT_PLANNER+="
--- $f ---
$(cat "$WORKSPACE/$f")
"
  fi
done

CONTEXT_RESEARCHER=""
for f in SOUL.md MEMORY.md; do
  if [[ -f "$WORKSPACE/$f" ]]; then
    CONTEXT_RESEARCHER+="
--- $f ---
$(cat "$WORKSPACE/$f")
"
  fi
done

CONTEXT_DOER="You are hive-trader. Your wallet: 0x7a3B...4f2E (Polygon), USDC balance: \$135.00, 1 open position (Chelsea/Burnley YES \$20@\$0.81). Tools: exec, web_fetch, read, write, sessions_send."

echo "  Planner context: $(echo "$CONTEXT_PLANNER" | wc -c) bytes"
echo "  Researcher context: $(echo "$CONTEXT_RESEARCHER" | wc -c) bytes"
echo "  Doer context: $(echo "$CONTEXT_DOER" | wc -c) bytes"

# --- Define prompts ---
read -r -d '' PROMPT_COORDINATION << 'PROMPT_EOF' || true
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
PROMPT_EOF

read -r -d '' PROMPT_ANALYSIS << 'PROMPT_EOF' || true
Scout just delivered the following scan results for high-confidence Polymarket soccer opportunities:

Markets:
1. Chelsea vs Burnley (Premier League) — Market: YES 0.81 / NO 0.19. Your estimate: 0.88 true probability. Volume: $45,200. Liquidity: $890,000. Chelsea home, Burnley bottom 3.
2. Barcelona vs Villarreal (La Liga) — Market: YES 0.72 / NO 0.28. Your estimate: 0.70 true probability. Volume: $38,500. Liquidity: $620,000. Barcelona 2nd, Villarreal 7th.
3. PSG vs Marseille (Ligue 1) — Market: YES 0.65 / NO 0.35. Your estimate: 0.78 true probability. Volume: $28,700. Liquidity: $450,000. Derby, PSG dominant at home.
4. RCD Mallorca vs RCD Espanyol (La Liga) — Market: YES 0.40 / NO 0.60. Your estimate: 0.45 true probability. Volume: $2,992. Liquidity: $601,377. Mid-table, tight odds.

Bankroll: $135 USDC. Risk limit: max 20% of bankroll ($27) per single trade.

Build a thesis for the highest-EV opportunity. Calculate expected value. Recommend position size using Kelly criterion. Output as structured JSON with fields: event, thesis, ev_calculation (show math), kelly_fraction, recommended_size_usd, confidence (1-10), risk_factors (array), recommendation (BUY/PASS with reasoning).

Also: briefly assess the other 3 opportunities (BUY or PASS for each, with one-line reasoning).
PROMPT_EOF

read -r -d '' PROMPT_EXECUTION << 'PROMPT_EOF' || true
Risk has approved the following trade:

APPROVED TRADE #2026-0313-001
Event: PSG vs Marseille — Ligue 1
Position: BUY YES (PSG win)
Price: $0.65
Size: $20 USDC
Kelly fraction: 0.15
Risk approval: hive-risk @ 2026-03-13T07:00:00Z
Expiry: Execute before 2026-03-16T20:45:00Z

Execute this trade. Provide the exact sequence of steps:
1. Pre-flight checks (balance verification, price validation)
2. USDC approval (if needed)
3. Order placement (exact API call format)
4. Fill verification
5. Position ledger update
6. Confirmation message to Risk and PM

For each step, show the actual API call or tool invocation. If a step fails, describe error handling.

IMPORTANT: Use real Polymarket CLOB API endpoints and formats. Do not invent endpoints. If you don't know the exact API format, say so.
PROMPT_EOF

# --- Model definitions ---
declare -A MODEL_ENDPOINTS MODEL_TYPES MODEL_KEYS MODEL_COST_IN MODEL_COST_OUT

MODEL_ENDPOINTS[deepseek-reasoner]="https://api.deepseek.com/chat/completions"
MODEL_ENDPOINTS[deepseek-chat]="https://api.deepseek.com/chat/completions"
MODEL_ENDPOINTS[claude-sonnet-4-6]="https://api.anthropic.com/v1/messages"
MODEL_ENDPOINTS[claude-sonnet-4-5-20250929]="https://api.anthropic.com/v1/messages"
MODEL_ENDPOINTS[gpt-4o]="https://api.openai.com/v1/chat/completions"
MODEL_ENDPOINTS[gemini-2.0-flash]="https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
MODEL_ENDPOINTS[grok-4-1-fast]="https://api.x.ai/v1/chat/completions"

MODEL_TYPES[deepseek-reasoner]="openai"
MODEL_TYPES[deepseek-chat]="openai"
MODEL_TYPES[claude-sonnet-4-6]="anthropic"
MODEL_TYPES[claude-sonnet-4-5-20250929]="anthropic"
MODEL_TYPES[gpt-4o]="openai"
MODEL_TYPES[gemini-2.0-flash]="google"
MODEL_TYPES[grok-4-1-fast]="openai"

MODEL_KEYS[deepseek-reasoner]="$DEEPSEEK_API_KEY"
MODEL_KEYS[deepseek-chat]="$DEEPSEEK_API_KEY"
MODEL_KEYS[claude-sonnet-4-6]="$ANTHROPIC_API_KEY"
MODEL_KEYS[claude-sonnet-4-5-20250929]="$ANTHROPIC_API_KEY"
MODEL_KEYS[gpt-4o]="$OPENAI_API_KEY"
MODEL_KEYS[gemini-2.0-flash]="$GEMINI_API_KEY"
MODEL_KEYS[grok-4-1-fast]="$XAI_API_KEY"

MODEL_COST_IN[deepseek-reasoner]=0.55;  MODEL_COST_OUT[deepseek-reasoner]=2.19
MODEL_COST_IN[deepseek-chat]=0.27;      MODEL_COST_OUT[deepseek-chat]=1.10
MODEL_COST_IN[claude-sonnet-4-6]=3.00;  MODEL_COST_OUT[claude-sonnet-4-6]=15.00
MODEL_COST_IN[claude-sonnet-4-5-20250929]=3.00;  MODEL_COST_OUT[claude-sonnet-4-5-20250929]=15.00
MODEL_COST_IN[gpt-4o]=2.50;             MODEL_COST_OUT[gpt-4o]=10.00
MODEL_COST_IN[gemini-2.0-flash]=0.10;   MODEL_COST_OUT[gemini-2.0-flash]=0.40
MODEL_COST_IN[grok-4-1-fast]=0.20;      MODEL_COST_OUT[grok-4-1-fast]=0.50

ALL_MODELS="deepseek-reasoner deepseek-chat claude-sonnet-4-6 claude-sonnet-4-5-20250929 gpt-4o gemini-2.0-flash grok-4-1-fast"

# --- Prompt map ---
declare -A PROMPT_TEXTS PROMPT_CONTEXTS PROMPT_SYSPREFIXES

PROMPT_TEXTS[coordination]="$PROMPT_COORDINATION"
PROMPT_TEXTS[analysis]="$PROMPT_ANALYSIS"
PROMPT_TEXTS[execution]="$PROMPT_EXECUTION"

PROMPT_CONTEXTS[coordination]="$CONTEXT_PLANNER"
PROMPT_CONTEXTS[analysis]="$CONTEXT_RESEARCHER"
PROMPT_CONTEXTS[execution]="$CONTEXT_DOER"

PROMPT_SYSPREFIXES[coordination]="You are Mhive, the Hive Architect & Manager. You design, bootstrap, coach, and hold accountable autonomous agent teams. Your workspace files are provided below as context."
PROMPT_SYSPREFIXES[analysis]="You are hive-analyst, the market thesis builder for PolyHive. Your job is to take Scout's raw market data and build actionable trading theses with expected value calculations and position sizing."
PROMPT_SYSPREFIXES[execution]="You are hive-trader, the execution agent for PolyHive. Your job is to execute approved trades on Polymarket's CLOB. Use real API formats only — do not invent endpoints."

ALL_PROMPTS="coordination analysis execution"

# --- API call functions ---

call_openai_compat() {
  local model="$1" endpoint="$2" key="$3" system="$4" user="$5" outfile="$6"
  local payload
  payload=$(jq -n \
    --arg model "$model" \
    --arg system "$system" \
    --arg user "$user" \
    --argjson max_tokens "$MAX_TOKENS" \
    '{model: $model, messages: [{role: "system", content: $system}, {role: "user", content: $user}], max_tokens: $max_tokens}')

  local start_ns end_ns
  start_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
  curl -s --max-time "$TIMEOUT" -X POST "$endpoint" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $key" \
    -d "$payload" > "$outfile.tmp" 2>&1
  end_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")

  local elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  # Wrap with metadata
  jq --arg elapsed_ms "$elapsed_ms" --arg ts "$TIMESTAMP" \
    '{benchmark_metadata: {elapsed_ms: ($elapsed_ms|tonumber), timestamp: $ts}, api_response: .}' \
    "$outfile.tmp" > "$outfile" 2>/dev/null || mv "$outfile.tmp" "$outfile"
  rm -f "$outfile.tmp"
  echo "$elapsed_ms"
}

call_anthropic() {
  local model="$1" endpoint="$2" key="$3" system="$4" user="$5" outfile="$6"
  local payload
  payload=$(jq -n \
    --arg model "$model" \
    --arg system "$system" \
    --arg user "$user" \
    --argjson max_tokens "$MAX_TOKENS" \
    '{model: $model, system: $system, messages: [{role: "user", content: $user}], max_tokens: $max_tokens}')

  local start_ns end_ns
  start_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
  curl -s --max-time "$TIMEOUT" -X POST "$endpoint" \
    -H "Content-Type: application/json" \
    -H "x-api-key: $key" \
    -H "anthropic-version: 2023-06-01" \
    -d "$payload" > "$outfile.tmp" 2>&1
  end_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")

  local elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  jq --arg elapsed_ms "$elapsed_ms" --arg ts "$TIMESTAMP" \
    '{benchmark_metadata: {elapsed_ms: ($elapsed_ms|tonumber), timestamp: $ts}, api_response: .}' \
    "$outfile.tmp" > "$outfile" 2>/dev/null || mv "$outfile.tmp" "$outfile"
  rm -f "$outfile.tmp"
  echo "$elapsed_ms"
}

call_google() {
  local model="$1" endpoint="$2" key="$3" system="$4" user="$5" outfile="$6"
  local payload
  payload=$(jq -n \
    --arg system "$system" \
    --arg user "$user" \
    '{systemInstruction: {parts: [{text: $system}]}, contents: [{parts: [{text: $user}]}], generationConfig: {maxOutputTokens: 2048}}')

  local start_ns end_ns
  start_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")
  curl -s --max-time "$TIMEOUT" -X POST "${endpoint}?key=${key}" \
    -H "Content-Type: application/json" \
    -d "$payload" > "$outfile.tmp" 2>&1
  end_ns=$(date +%s%N 2>/dev/null || echo "$(date +%s)000000000")

  local elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  jq --arg elapsed_ms "$elapsed_ms" --arg ts "$TIMESTAMP" \
    '{benchmark_metadata: {elapsed_ms: ($elapsed_ms|tonumber), timestamp: $ts}, api_response: .}' \
    "$outfile.tmp" > "$outfile" 2>/dev/null || mv "$outfile.tmp" "$outfile"
  rm -f "$outfile.tmp"
  echo "$elapsed_ms"
}

# --- CSV header ---
echo "model,prompt,latency_ms,input_tokens,output_tokens,cost_usd,timestamp" > "$RESULTS_DIR/timing.csv"

# --- Run benchmarks ---
echo ""
echo "=== LLM Benchmark — $TODAY ==="
echo "=== Models: $(echo $ALL_MODELS | wc -w | tr -d ' '), Prompts: $(echo $ALL_PROMPTS | wc -w | tr -d ' ') ==="
echo ""

for model in $ALL_MODELS; do
  # Filter check
  if [[ -n "$FILTER_MODELS" ]] && ! echo ",$FILTER_MODELS," | grep -q ",$model,"; then
    continue
  fi

  for prompt_name in $ALL_PROMPTS; do
    if [[ -n "$FILTER_PROMPTS" ]] && ! echo ",$FILTER_PROMPTS," | grep -q ",$prompt_name,"; then
      continue
    fi

    outfile="$RAW_DIR/${model}_${prompt_name}.json"
    system_text="${PROMPT_SYSPREFIXES[$prompt_name]}

${PROMPT_CONTEXTS[$prompt_name]}"
    user_text="${PROMPT_TEXTS[$prompt_name]}"
    api_type="${MODEL_TYPES[$model]}"
    endpoint="${MODEL_ENDPOINTS[$model]}"
    key="${MODEL_KEYS[$model]}"

    printf "  %-35s %-15s ... " "$model" "$prompt_name"

    elapsed_ms=0
    case "$api_type" in
      openai)   elapsed_ms=$(call_openai_compat "$model" "$endpoint" "$key" "$system_text" "$user_text" "$outfile") ;;
      anthropic) elapsed_ms=$(call_anthropic "$model" "$endpoint" "$key" "$system_text" "$user_text" "$outfile") ;;
      google)   elapsed_ms=$(call_google "$model" "$endpoint" "$key" "$system_text" "$user_text" "$outfile") ;;
    esac

    elapsed_s=$(echo "scale=1; $elapsed_ms / 1000" | bc 2>/dev/null || echo "?")

    # Extract tokens from response (best-effort)
    in_tok=0; out_tok=0
    if [[ -f "$outfile" ]]; then
      case "$api_type" in
        openai)
          in_tok=$(jq -r '.api_response.usage.prompt_tokens // 0' "$outfile" 2>/dev/null || echo 0)
          out_tok=$(jq -r '.api_response.usage.completion_tokens // 0' "$outfile" 2>/dev/null || echo 0)
          ;;
        anthropic)
          in_tok=$(jq -r '.api_response.usage.input_tokens // 0' "$outfile" 2>/dev/null || echo 0)
          out_tok=$(jq -r '.api_response.usage.output_tokens // 0' "$outfile" 2>/dev/null || echo 0)
          ;;
        google)
          in_tok=$(jq -r '.api_response.usageMetadata.promptTokenCount // 0' "$outfile" 2>/dev/null || echo 0)
          out_tok=$(jq -r '.api_response.usageMetadata.candidatesTokenCount // 0' "$outfile" 2>/dev/null || echo 0)
          ;;
      esac
    fi

    # Calculate cost
    cost_in="${MODEL_COST_IN[$model]}"
    cost_out="${MODEL_COST_OUT[$model]}"
    cost=$(echo "scale=4; ($in_tok * $cost_in + $out_tok * $cost_out) / 1000000" | bc 2>/dev/null || echo "0")

    printf "%6ss  %5d/%5d tok  \$%s\n" "$elapsed_s" "$in_tok" "$out_tok" "$cost"

    # Write CSV row
    echo "$model,$prompt_name,$elapsed_ms,$in_tok,$out_tok,$cost,$TIMESTAMP" >> "$RESULTS_DIR/timing.csv"
  done
done

# --- Generate summary ---
echo ""
echo "=== Generating summary ==="

cat > "$RESULTS_DIR/summary.md" << SUMMARY_EOF
# LLM Benchmark Results — $TODAY

**Run at:** $TIMESTAMP
**Workspace context:** $(echo "$CONTEXT_PLANNER" | wc -c | tr -d ' ') bytes (planner), $(echo "$CONTEXT_RESEARCHER" | wc -c | tr -d ' ') bytes (researcher)
**Max tokens:** $MAX_TOKENS
**Timeout:** ${TIMEOUT}s

## Timing & Cost

| Model | Coordination | Analysis | Execution | Avg Latency | Total Cost |
|-------|-------------|----------|-----------|-------------|------------|
SUMMARY_EOF

for model in $ALL_MODELS; do
  if [[ -n "$FILTER_MODELS" ]] && ! echo ",$FILTER_MODELS," | grep -q ",$model,"; then
    continue
  fi
  row="| $model |"
  total_ms=0; total_cost=0; count=0
  for prompt_name in $ALL_PROMPTS; do
    if [[ -n "$FILTER_PROMPTS" ]] && ! echo ",$FILTER_PROMPTS," | grep -q ",$prompt_name,"; then
      continue
    fi
    line=$(grep "^$model,$prompt_name," "$RESULTS_DIR/timing.csv" | tail -1)
    if [[ -n "$line" ]]; then
      ms=$(echo "$line" | cut -d, -f3)
      cost=$(echo "$line" | cut -d, -f6)
      secs=$(echo "scale=1; $ms / 1000" | bc 2>/dev/null || echo "?")
      row+=" ${secs}s / \$$cost |"
      total_ms=$((total_ms + ms))
      total_cost=$(echo "$total_cost + $cost" | bc 2>/dev/null || echo "0")
      count=$((count + 1))
    else
      row+=" — |"
    fi
  done
  if [[ $count -gt 0 ]]; then
    avg_s=$(echo "scale=1; $total_ms / $count / 1000" | bc 2>/dev/null || echo "?")
    row+=" ${avg_s}s | \$$total_cost |"
  else
    row+=" — | — |"
  fi
  echo "$row" >> "$RESULTS_DIR/summary.md"
done

cat >> "$RESULTS_DIR/summary.md" << 'SUMMARY_EOF2'

## Quality Scores (manual review — 1 to 5)

| Model | Coordination | Analysis | Execution | Overall | Notes |
|-------|-------------|----------|-----------|---------|-------|
| deepseek-reasoner | | | | | |
| deepseek-chat | | | | | |
| claude-sonnet-4-6 | | | | | |
| claude-sonnet-4-5 | | | | | |
| gpt-4o | | | | | |
| gemini-2.0-flash | | | | | |
| grok-4-1-fast | | | | | |

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
SUMMARY_EOF2

echo ""
echo "=== Done ==="
echo "Results: $RESULTS_DIR/"
echo "Summary: $RESULTS_DIR/summary.md"
echo "Timing:  $RESULTS_DIR/timing.csv"
echo "Raw:     $RAW_DIR/"
