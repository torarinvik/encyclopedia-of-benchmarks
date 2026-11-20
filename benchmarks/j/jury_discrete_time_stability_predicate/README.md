# Jury discrete-time stability predicate

This package classifies a bounded real polynomial as strictly Schur stable:
every root must lie inside the open unit disk. It reads exact integer
coefficients and does not calculate or approximate roots.

## Contract

The exported symbol is `jury_discrete_time_stability_predicate` in the
`i64_array_scalar` ABI. Input is `[degree, a0, a1, ..., an]`, representing
`p(z)=a0*z^degree + ... + an` in descending-power order. The degree is 1–4,
each coefficient is in `[-9,9]`, and `a0` must be nonzero. A negative leading
coefficient is normalized by negating the entire coefficient vector.

Return `1` exactly when all roots satisfy `|z| < 1`. Return `0` for a valid
polynomial that is unstable or has any root on `|z|=1`. Return `-1` for null,
malformed, or out-of-profile input. This profile concerns strict discrete-time
stability only; it makes no claim about non-strict stability or root counts.

## Algorithm profiles

The primary reference and native ports use the division-free 1961 Jury–Blanchard
table. First require `p(1)>0` and `(-1)^degree * p(-1)>0`. Normalize the leading
coefficient to positive. For each current coefficient row `c` of degree `k`,
from the original degree down through degree 1, require `|c[0]| > |c[k]|`.
When `k>1`, form the next row as
`d[i] = c[0]*c[i] - c[k]*c[k-i]` for `i=0..k-1`. Equality is rejected. The
last degree-1 comparison is an explicit terminal check; the endpoint conditions
propagate through each strict reduction and make this last check redundant, but
including it makes the accepted row sequence explicit. This division-free
version has no quotient pivot or epsilon rule.

The independent reference constructs the Schur–Cohn matrix `X Xᵀ - Y Yᵀ` and
checks its leading principal determinants by exact cofactor expansion. For
descending coefficients `c[0..n]`, `X[i,j]=c[i-j]` and
`Y[i,j]=c[n-(i-j)]` when `j<=i`, with zero entries above the diagonal. Strict
positive definiteness is equivalent to every root lying in the open unit disk.

All native arithmetic is signed 64-bit integer arithmetic. With degree at most
four and input coefficient magnitude at most nine, the successive row bounds
are 9, 162, 52,488, and 5,509,980,288. The Schur–Cohn entries are bounded by
648 in magnitude; order-four determinant expansion stays within signed 64-bit range.
Native fixed scratch uses at most five coefficients and two five-element rows;
the workspace cap is 1,024 bytes.

The package distinguishes this unit-disk criterion from the continuous-time
Routh–Hurwitz test in
[`routh_hurwitz_stability_predicate`](../routh_hurwitz_stability_predicate/README.md),
which checks for roots in the open left half-plane. Other polynomial packages
in this repository approximate roots or perform unrelated operations.

## Sources and workload

The pinned RosettaCodeData [popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used only to discover the task title at score 7. The table profile follows
Jury and Blanchard’s 1961 note, “A Stability Test for Linear Discrete Systems
in Table Form,” *Proceedings of the IRE* 49, 1947–1948. The related 1962 paper
is [“A Simplified Stability Criterion for Linear Discrete Systems”](https://doi.org/10.1109/JRPROC.1962.288193).
Choo’s [elementary proof of the Jury test](https://doi.org/10.1016/j.automatica.2010.10.040)
states the strict open-unit-disk result. The independent matrix formulation is
based on the scalar Schur–Cohn theorem described by
[Dym and Young](https://doi.org/10.1017/S0013091500004806).

Fixtures are original hand-derived coefficient vectors. They cover stable and
unstable linear through quartic cases, sign normalization, roots at both real
unit-circle endpoints, a unit-circle conjugate pair, a reciprocal-root
polynomial that makes the first table row equality singular, and malformed input. Package-local static
workload and inventory helpers are provided but have not been run.

## Native ports

| Language | Source |
|---|---|
| C | [`jury_discrete_time_stability_predicate.c`](../../../c/j/jury_discrete_time_stability_predicate.c) |
| C3 | [`jury_discrete_time_stability_predicate.c3`](../../../c3/j/jury_discrete_time_stability_predicate.c3) |
| C++ | [`jury_discrete_time_stability_predicate.cpp`](../../../cpp/j/jury_discrete_time_stability_predicate.cpp) |
| Elisa | [`jury_discrete_time_stability_predicate.elisa`](../../../elisa/j/jury_discrete_time_stability_predicate.elisa) |
| Mojo | [`jury_discrete_time_stability_predicate.mojo`](../../../mojo/j/jury_discrete_time_stability_predicate.mojo) |
| Nim | [`jury_discrete_time_stability_predicate.nim`](../../../nim/j/jury_discrete_time_stability_predicate.nim) |
| Odin | [`jury_discrete_time_stability_predicate.odin`](../../../odin/j/jury_discrete_time_stability_predicate.odin) |
| Rust | [`jury_discrete_time_stability_predicate.rs`](../../../rust/j/jury_discrete_time_stability_predicate.rs) |
| V | [`jury_discrete_time_stability_predicate.v`](../../../v/j/jury_discrete_time_stability_predicate.v) |
| Zig | [`jury_discrete_time_stability_predicate.zig`](../../../zig/j/jury_discrete_time_stability_predicate.zig) |

See [RIGHTS.md](RIGHTS.md), [INVENTORY.md](INVENTORY.md), and
[`INVENTORY.json`](INVENTORY.json) for provenance and file accounting. The
package is registered with the shared `i64_array_scalar` runner and verifier,
root README, and catalog.
