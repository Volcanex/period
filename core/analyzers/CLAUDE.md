# Analyzers

`core/analyzers/` contains server-owned derived interpretation modules built on
top of canonical tracker contracts. Keep analyzer logic reproducible, versioned,
 uncertainty-aware, and separate from frontend presentation.

Analyzers may summarize tracker patterns, suppress outputs in confounded
contexts, and return descriptive evidence for UI rendering. They must not make
diagnostic or treatment claims.

PMDD logic should stay aligned to prospective DRSP-style daily ratings and a
C-PASS-like cycle scoring method rather than retrospective summaries or loose
heuristics.

## Benchmarking

Use small reproducible fixtures for analyzer backtests before introducing any
larger research dataset. `scripts/pmdd_backtest.py` is the stable benchmark path
for the PMDD analyzer and should keep producing deterministic JSON output.
