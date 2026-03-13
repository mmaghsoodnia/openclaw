# Test 2: ANALYSIS (Researcher Task)

## System Context Files

- SOUL.md
- MEMORY.md

## System Prompt Prefix

You are hive-analyst, the market thesis builder for PolyHive. Your job is to take Scout's raw market data and build actionable trading theses with expected value calculations and position sizing.

## User Prompt

Scout just delivered the following scan results for high-confidence Polymarket soccer opportunities:

```json
{
  "scan_timestamp": "2026-03-13T06:00:00Z",
  "markets": [
    {
      "event": "Chelsea vs Burnley — Premier League",
      "question": "Will Chelsea win?",
      "market_odds": { "yes": 0.81, "no": 0.19 },
      "your_estimated_probability": 0.88,
      "volume_24h_usd": 45200,
      "total_liquidity_usd": 890000,
      "event_date": "2026-03-15T15:00:00Z",
      "notes": "Chelsea home, Burnley bottom 3, Chelsea won last 5 home matches"
    },
    {
      "event": "Barcelona vs Villarreal — La Liga",
      "question": "Will Barcelona win?",
      "market_odds": { "yes": 0.72, "no": 0.28 },
      "your_estimated_probability": 0.7,
      "volume_24h_usd": 38500,
      "total_liquidity_usd": 620000,
      "event_date": "2026-03-15T20:00:00Z",
      "notes": "Barcelona 2nd, Villarreal 7th, close recent form"
    },
    {
      "event": "PSG vs Marseille — Ligue 1",
      "question": "Will PSG win?",
      "market_odds": { "yes": 0.65, "no": 0.35 },
      "your_estimated_probability": 0.78,
      "volume_24h_usd": 28700,
      "total_liquidity_usd": 450000,
      "event_date": "2026-03-16T20:45:00Z",
      "notes": "Derby match, PSG dominant at home, Marseille inconsistent away"
    },
    {
      "event": "RCD Mallorca vs RCD Espanyol — La Liga",
      "question": "Will Mallorca win?",
      "market_odds": { "yes": 0.4, "no": 0.6 },
      "your_estimated_probability": 0.45,
      "volume_24h_usd": 2992,
      "total_liquidity_usd": 601377,
      "event_date": "2026-03-16T18:30:00Z",
      "notes": "Mid-table clash, tight odds, low volume"
    }
  ]
}
```

Bankroll: $135 USDC. Risk limit: max 20% of bankroll per single trade.

Build a thesis for the highest-EV opportunity. Calculate expected value. Recommend position size using Kelly criterion. Output your full analysis as structured JSON with these fields: event, thesis, ev_calculation (show work), kelly_fraction, recommended_size_usd, confidence (1-10), risk_factors (array), recommendation (BUY/PASS with reasoning).

Also: should we take any of the other 3 opportunities? Briefly assess each.

## Scoring Criteria (1-5 each)

1. **Math Accuracy** — Is the EV calculation correct? (EV = p_estimated × payout - (1-p_estimated) × stake). Is Kelly correct? (f = (bp - q) / b where b = odds payout)
2. **Correct Identification** — Does it identify PSG (edge = 0.78-0.65 = 0.13) as highest EV, not Chelsea (edge = 0.07)?
3. **JSON Quality** — Is the output valid, well-structured JSON with all requested fields?
4. **Risk Awareness** — Does it flag Barcelona as negative EV (estimated 0.70 < market 0.72)? Does it flag Mallorca as low-volume/risky?
5. **Practical Judgment** — Does it respect the 20% bankroll limit ($27 max)? Does it avoid over-betting?
