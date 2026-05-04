# Cycle Model

`core/model/` contains a dependency-free reference implementation of the core
cycle-length model shape. It is research scaffolding for parity, tests, and
future Flutter implementation, not a server-owned production calculator.

The model follows the literature direction: population shrinkage for sparse
histories, sequential updates, interval calibration, and explicit self-tracking
skip-artifact handling. Keep medical uncertainty visible and do not add
diagnosis logic here.

## Dataset Provenance

The vendored benchmark fixture is `tests/data/urteaga_cycle_lengths.npz`, copied
from the public `iurteaga/menstrual_cycle_analysis` repository. It contains
cycle lengths and skip labels for generative predictive modeling and is suitable
for repeatable local backtests.

Related research to cite when interpreting results:

- Bortot, Masarotto, and Vidoni, Biostatistics 2010: Bayesian state-space cycle-length prediction with population shrinkage.
- Urteaga et al., PMLR 2021: calibrated generative menstrual-cycle modeling with generalized-Poisson likelihoods.
- Li et al., JAMIA 2022 / arXiv:2102.12439: hierarchical cycle prediction with explicit self-tracking artifact modeling on Clue-scale data.

mcPHASES is richer because it includes hormone and self-report signals, but it
is restricted by a PhysioNet data-use agreement. Treat it as a future external
validation target, not a vendored fixture.

## Benchmarking

Run `python3 scripts/model_benchmark.py` to print a stable JSON report. The
script learns priors and interval calibration on calibration subjects, then
reports held-out validation metrics. Keep this path stable so model changes can
be compared over time.
