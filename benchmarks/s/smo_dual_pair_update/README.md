# SMO dual pair update

This package measures one analytic two-coefficient update from Sequential
Minimal Optimization (SMO). It operates on an already feasible binary SVM dual
state, a supplied linear feature matrix, and a selected pair. It is not a full
training loop: no working-pair search, stopping loop, kernel cache, or classifier
prediction is included.

## Contract

The `float64_slice_io` input is
`[N,D,C_milli,b_milli,labels[N],alpha_milli[N],X[N*D],i,j]`. Every field must
be a finite, integer-valued float64. The exact length is `6+2*N+N*D`, with
`2<=N<=8` and `1<=D<=3`; the maximum valid and parseable lengths are 46 and
47 values. `C_milli` is in `1..5000` and represents `C=C_milli/1000`;
`b_milli` is in `[-1000000,1000000]` and represents the current bias. Labels
are ±1 and both classes must occur. `alpha_milli[k]` lies in
`[0,C_milli]`, with `sum(labels[k]*alpha_milli[k])=0`. Row-major integer feature
coordinates lie in `[-32,32]`. Pair indices are distinct and in `0..N-1`.

The update uses the linear kernel `K(x,z)=x·z`. It computes the feasible
interval for the selected pair, applies the SMO analytic update when the pair
curvature is positive, and compares the interval endpoints when the curvature
is zero. It then preserves the dual equality constraint and updates the bias
from the two candidate threshold values, using their average when both updated
coefficients are at a box bound. Output is `[alpha'[0],...,alpha'[N-1],b']`,
with `N+1` float64 values. The absolute and relative output tolerances are
`1e-12`. Success returns `N+1`; malformed input returns `-1`; a valid input
with a null output or capacity below `N+1` returns `-2` without writing.
Input errors take precedence over output errors. The maximum valid input length
is 46 values, the maximum output is 9 values (72 bytes), and declared workspace
is 1024 bytes. The pair update takes O(ND+N²D) work in the zero-curvature
endpoint case and O(ND) work otherwise; it uses O(ND) bounded storage.

The primary oracle follows SMO's eta, clipping, endpoint, and bias rules. The
independent verifier directly maximizes the restricted dual objective by
evaluating its feasible endpoints and stationary point. The workload includes
opposite-label clipping, an interior pair update, a zero-curvature duplicate
feature pair, same-label updates, the maximum frame, and malformed/ABI cases.

## Provenance and rights

The book crosswalk identifies SMO training as an algorithm in Cristianini and
Ricci, “Support Vector Machines,” *Encyclopedia of Algorithms*, DOI
[10.1007/978-1-4939-2864-4_415](https://doi.org/10.1007/978-1-4939-2864-4_415).
The analytic pair update follows John C. Platt, [“Sequential Minimal
Optimization: A Fast Algorithm for Training Support Vector Machines,”
MSR-TR-98-14](https://www.microsoft.com/en-us/research/publication/sequential-minimal-optimization-a-fast-algorithm-for-training-support-vector-machines/).
Both sources are copyrighted by their publishers/authors. This package uses
the algorithm description and equations only; the bounded contract, workload,
oracles, and ten ports are independently written without copying source code or
prose. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the
[primary oracle](../../smo_dual_pair_update_oracle.py), the
[independent verifier](../../smo_dual_pair_update_verifier_oracle.py), and the
[static inventory checker](../../check_smo_dual_pair_update_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/smo_dual_pair_update.c`](../../../c/s/smo_dual_pair_update.c) |
| C3 | [`c3/s/smo_dual_pair_update.c3`](../../../c3/s/smo_dual_pair_update.c3) |
| C++ | [`cpp/s/smo_dual_pair_update.cpp`](../../../cpp/s/smo_dual_pair_update.cpp) |
| Elisa | [`elisa/s/smo_dual_pair_update.elisa`](../../../elisa/s/smo_dual_pair_update.elisa) |
| Mojo | [`mojo/s/smo_dual_pair_update.mojo`](../../../mojo/s/smo_dual_pair_update.mojo) |
| Nim | [`nim/s/smo_dual_pair_update.nim`](../../../nim/s/smo_dual_pair_update.nim) |
| Odin | [`odin/s/smo_dual_pair_update.odin`](../../../odin/s/smo_dual_pair_update.odin) |
| Rust | [`rust/s/smo_dual_pair_update.rs`](../../../rust/s/smo_dual_pair_update.rs) |
| V | [`v/s/smo_dual_pair_update.v`](../../../v/s/smo_dual_pair_update.v) |
| Zig | [`zig/s/smo_dual_pair_update.zig`](../../../zig/s/smo_dual_pair_update.zig) |

The source inventory is checked by
[`benchmarks/check_smo_dual_pair_update_package.py`](../../check_smo_dual_pair_update_package.py).
