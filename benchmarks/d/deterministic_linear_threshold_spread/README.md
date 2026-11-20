# Deterministic linear-threshold spread

This package computes the final active set of a directed graph under fixed
linear thresholds. It implements the queue-based influence-computation
procedure in Chapter 710's deterministic-threshold reference: start from a
seed set, add each newly active vertex's outgoing weights to its targets, and
activate a target once its accumulated weight reaches its threshold.

## Bounded contract

- ABI: `i64_array_bytes_output`; symbol `deterministic_linear_threshold_spread`.
- Input: `[n,m,s,seed_0,...,seed_(s-1),(u,v,w)*m,t_0,...,t_(n-1)]`.
- `1<=n<=8`, `0<=m<=24`, `0<=s<=n`. The graph is directed and simple,
  self-loops are rejected, seeds are distinct, and each edge weight is an
  integer from 0 through 16. The sum of incoming edge weights at each vertex
  is at most 16. Every vertex threshold is an integer from 1 through 16.
  Integers represent values scaled by a common denominator of 16, preserving
  exact comparisons for this bounded input domain.
- Seeds activate at round 0. In each synchronous wave, only the frontier
  active at the beginning of that wave contributes weight. All newly
  qualifying vertices activate together in the next wave. Activation is
  permanent. This yields the same final closure as the source queue procedure
  while making activation rounds observable.
- Output is `[n,wave_count,round(v0),...,round(v(n-1))]` as little-endian
  signed i64 words. A vertex that never activates has round `-1`; seeds have
  round 0. `wave_count` is the largest positive activation round, or zero if
  no non-seed vertex activates. Maximum valid input is 91 words and the
  parser accepts 92 words to classify a trailing word as malformed. Maximum
  output is 80 bytes and workspace is bounded to 2,048 bytes.
- Invalid input returns `-1`; null or short output returns `-2` without
  writes. Inputs are fully validated before output-capacity handling.

The primary reference uses a frontier queue and incrementally accumulates
incoming weights. The independent reference rescans all inactive vertices
against the current active set at each wave. Both report the same canonical
per-vertex activation rounds.

This is distinct from [`influence_maximization_greedy_linear_threshold`](../influence_maximization_greedy_linear_threshold/README.md),
which uses sampled random triggering parents and greedily chooses a seed set,
and from [`influence_maximization_greedy_live_edge`](../influence_maximization_greedy_live_edge/README.md),
which replays IC live-edge worlds. Neither computes closure for fixed
deterministic thresholds.

## Sources and rights

The chapter is Lu and Wu, “Influence Maximization,” *Encyclopedia of
Algorithms*, Chapter 710, DOI
[10.1007/978-1-4939-2864-4_710](https://doi.org/10.1007/978-1-4939-2864-4_710).
The operational method is Lu, Zhang, Wu, Fu, and Du, “Approximation and
Inapproximation for the Influence Maximization Problem in Social Networks
under Deterministic Linear Threshold Model,” §II, Algorithm 1, DOI
[10.1109/ICDCSW.2011.33](https://doi.org/10.1109/ICDCSW.2011.33). These sources
are used for attribution and algorithm semantics only. No source code, prose,
figures, or fixtures are reused; see [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary reference](primary_oracle.py)
- [independent reference](independent_oracle.py)
- [`INVENTORY.md`](INVENTORY.md) and [`INVENTORY.json`](INVENTORY.json)
- [`check_inventory.py`](check_inventory.py) and
  [`verify_workload.py`](verify_workload.py)

| Language | Port |
|---|---|
| C | [`c/deterministic_linear_threshold_spread.c`](../../../c/deterministic_linear_threshold_spread.c) |
| C3 | [`c3/deterministic_linear_threshold_spread.c3`](../../../c3/deterministic_linear_threshold_spread.c3) |
| C++ | [`cpp/deterministic_linear_threshold_spread.cpp`](../../../cpp/deterministic_linear_threshold_spread.cpp) |
| Elisa | [`elisa/deterministic_linear_threshold_spread.elisa`](../../../elisa/deterministic_linear_threshold_spread.elisa) |
| Mojo | [`mojo/deterministic_linear_threshold_spread.mojo`](../../../mojo/deterministic_linear_threshold_spread.mojo) |
| Nim | [`nim/deterministic_linear_threshold_spread.nim`](../../../nim/deterministic_linear_threshold_spread.nim) |
| Odin | [`odin/deterministic_linear_threshold_spread.odin`](../../../odin/deterministic_linear_threshold_spread.odin) |
| Rust | [`rust/deterministic_linear_threshold_spread.rs`](../../../rust/deterministic_linear_threshold_spread.rs) |
| V | [`v/deterministic_linear_threshold_spread.v`](../../../v/deterministic_linear_threshold_spread.v) |
| Zig | [`zig/deterministic_linear_threshold_spread.zig`](../../../zig/deterministic_linear_threshold_spread.zig) |

Shared `i64_array_bytes_output` runner/verifier and catalog integration are
complete. No programs, tests, scripts, checkers, builds, compilers, profilers,
or benchmarks were run.
