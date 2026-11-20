# Deterministic bounded SMO training trace

This package profiles the complete Sequential Minimal Optimization training
loop from Platt's §2.5 pseudocode: KKT checks, deterministic partner selection,
analytic two-multiplier updates, and the alternating full/non-bound outer
scans. It is distinct from [`smo_dual_pair_update`](../smo_dual_pair_update/README.md),
which performs one update for a caller-supplied pair and does not select
examples or control training passes. It is also distinct from
[`support_vector_classifier`](../support_vector_classifier/README.md), which
fits a classifier using projected-gradient optimization.

## Contract

The `float64_slice_io` input is
`[N,D,C_milli,pass_cap,labels[N],X[N*D]]`. Every value must be a finite,
integer-valued float64. `2<=N<=8`, `1<=D<=3`, `1<=C_milli<=5000`,
`1<=pass_cap<=16`, labels are ±1 with both classes present, and row-major
feature coordinates lie in `[-32,32]`. The linear kernel is the dot product.
The initial dual multipliers and intercept are zero; `C=C_milli/1000`.
Input length is exactly `4+N+N*D`, at most 36 valid values and 37 parseable
values.

The profile fixes Platt's KKT tolerance and step epsilon to `0.001`. Each full
or non-bound scan visits examples in ascending input order. The preferred
partner maximizes `|E_i-E_j|`, with lowest index on a tie. If that pair does not
move, candidates are tried in ascending order through the current non-bound
examples and then through all examples. The paper's randomized scan starting
positions are replaced by these deterministic zero-based starts. A non-bound
scan visits an example when its coefficient is strictly between `0` and `C`
at the time that index is reached.
For the local ABI, the decision score is `sum(alpha_i*y_i*K(x_i,x)) + bias`;
the emitted `bias` is the negative of Platt's subtractive threshold `b`.

The outer loop starts with a full scan and follows the source toggle rule:
after a full scan, the next pass scans non-bound coefficients; after a
non-bound pass with zero changes, the next pass is full. Training stops when
the source loop condition becomes false or `pass_cap` passes have completed.
Output is `[passes_completed,changes_in_last_pass,converged,alpha[0..N),bias]`;
`converged` is one only when the source stopping condition is reached before
the cap. It does not claim convergence when the finite pass budget expires.
Static source review aligned this boundary in all ten ports and both reference
implementations. This correction has not been executed.
The maximum output is 12 float64 values (96 bytes); declared fixed workspace is
4096 bytes. A null/short output returns `-2`; malformed input returns `-1`
before output-capacity checks, and errors leave output untouched.

## References and workload

The primary reference follows Platt's curvature update, clipping, threshold
selection, and full `takeStep` / `examineExample` / main-loop control. The
independent reference derives the pair stationary point from the full dual
gradient and directly scores feasible endpoints when curvature is zero. The
workload includes an interior update, duplicate-vector endpoint handling,
pass-cap termination, a maximum-size frame, invalid input, and ABI probes.

## Provenance and rights

The book chapter is Cristianini and Ricci, “Support Vector Machines,”
*Encyclopedia of Algorithms*, Chapter 415, DOI
[10.1007/978-1-4939-2864-4_415](https://doi.org/10.1007/978-1-4939-2864-4_415).
The operational method is John C. Platt, [“Sequential Minimal Optimization:
A Fast Algorithm for Training Support Vector Machines,” MSR-TR-98-14
(1998)](https://www.microsoft.com/en-us/research/publication/sequential-minimal-optimization-a-fast-algorithm-for-training-support-vector-machines/),
§§2.1–2.5. This package uses the mathematical procedure only; no source code,
book prose, or fixtures are reused. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/smo_deterministic_training.c`](../../../c/s/smo_deterministic_training.c) |
| C3 | [`c3/s/smo_deterministic_training.c3`](../../../c3/s/smo_deterministic_training.c3) |
| C++ | [`cpp/s/smo_deterministic_training.cpp`](../../../cpp/s/smo_deterministic_training.cpp) |
| Elisa | [`elisa/s/smo_deterministic_training.elisa`](../../../elisa/s/smo_deterministic_training.elisa) |
| Mojo | [`mojo/s/smo_deterministic_training.mojo`](../../../mojo/s/smo_deterministic_training.mojo) |
| Nim | [`nim/s/smo_deterministic_training.nim`](../../../nim/s/smo_deterministic_training.nim) |
| Odin | [`odin/s/smo_deterministic_training.odin`](../../../odin/s/smo_deterministic_training.odin) |
| Rust | [`rust/s/smo_deterministic_training.rs`](../../../rust/s/smo_deterministic_training.rs) |
| V | [`v/s/smo_deterministic_training.v`](../../../v/s/smo_deterministic_training.v) |
| Zig | [`zig/s/smo_deterministic_training.zig`](../../../zig/s/smo_deterministic_training.zig) |

Primary and independent references are [`smo_deterministic_training_oracle.py`](../../smo_deterministic_training_oracle.py)
and [`smo_deterministic_training_verifier_oracle.py`](../../smo_deterministic_training_verifier_oracle.py).
The pinned fixtures are in [`workload.json`](workload.json); package file
coverage is listed in [`INVENTORY.md`](INVENTORY.md) and the exact source-to-
profile mapping is in [`SOURCE_CROSSWALK.md`](SOURCE_CROSSWALK.md). The package
provides [`verify_workload.py`](verify_workload.py) and
[`check_inventory.py`](check_inventory.py) for later static verification.
