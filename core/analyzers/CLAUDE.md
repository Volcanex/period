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

PCOS logic must stay aligned to the 2023 International Evidence-based Guideline
for the Assessment and Management of Polycystic Ovary Syndrome (Teede et al.,
J Clin Endocrinol Metab 108:2447). Self-report can only address two of the
three Rotterdam features (ovulatory dysfunction and clinical hyperandrogenism);
polycystic ovary morphology on ultrasound or elevated AMH stays clinician-owned
and is surfaced as a recommended follow-up rather than estimated. The analyzer
must apply age-of-menarche rules for cycle irregularity, recognise hormonal
contraception/pregnancy/postpartum/lactation as suppressors (with the COCP
3-month washout caveat), and always include differential reminders (thyroid,
hyperprolactinemia, NCAH, Cushing syndrome, androgen-secreting tumour, primary
ovarian insufficiency, acromegaly, iatrogenic causes).

## Benchmarking

Use small reproducible fixtures for analyzer backtests before introducing any
larger research dataset. `scripts/pmdd_backtest.py` and `scripts/pcos_backtest.py`
are the stable benchmark paths for the PMDD and PCOS analyzers and should keep
producing deterministic JSON output. Regenerate fixtures with
`scripts/build_pcos_backtest_cases.py` rather than editing the JSON by hand.
