# Wynn epsilon sequence algorithm

This package computes multiple columns of Wynn's epsilon tableau for one
finite real sequence. It implements the recurrence in NIST DLMF §3.9(iv),
Eq. 3.9.11, through order `2K`, then returns all even rows `ε₂, ε₄, …, ε₂K`.
Those rows are the successive Shanks transforms. The local Aitken Δ² package
handles a single order-one transform on each isolated triple; it does not
build or reuse a multi-column tableau.

The input is `[N,K,s₀,…,s_(N-1)]` as float64 values. `N` is 5 through 10,
`K` is 2 or 3, `N >= 2K+1`, and each finite sample lies in `[-2,2]` on the
exact `1/256` grid. The valid frame has `N+2` values (at most 12); 13 values
are parseable so a trailing-value rejection is covered.

For each recurrence cell, implementations first compute the binary64
denominator as `right - left`, then its reciprocal, then add the auxiliary
cell. A computed `+0.0` or `-0.0` denominator, a singular dependency, or a
nonfinite denominator, reciprocal, or result marks that cell unavailable. The marker
propagates; no alternate recurrence or substitute value is introduced. An
available output pair is `[0,value]`; an unavailable pair is `[1,0]`. This
operational binary64 rule is intentional so the ten ports agree on singular
cells. The code must not be compiled with fast-math transformations.

Output pairs are ordered by even row and then increasing sequence index. The
result is the number of output float64 elements. The maximum is 36 elements
for `N=10,K=3`. Malformed input returns `-1`; a null or undersized output
returns `-2`; errors write no output. Tolerance is `1e-9` absolute and
`1e-12` relative. Fixed scratch space is capped at 2,048 bytes, and caller
output capacity is bounded at 36 float64 elements.

The primary reference directly fills the epsilon tableau. The independent
reference uses DLMF's Hankel determinant ratio for finite even-column values;
it replays the specified rounded recurrence only to classify operational
singularities. Its tiny determinants are expanded using integer-scaled input
values: `x=256s` is within `[-512,512]`; the order-four numerator determinant
is bounded by `4!·512⁴ < 2⁴¹`, and the order-three second-difference
denominator, including its factor 256, is below `2⁴⁴`. If exact integer
determinant cancellation says zero while the rounded
tableau still marks a cell finite, or if the determinant quotient differs from
the operational cell by more than the published tolerance, the reference uses
that already-computed finite tableau value. The determinant is an independent
check on stable cells; the rounded recurrence remains the output contract for
ill-conditioned cells. The profile is bounded to `K<=3`; primary work is
`O(NK)`, while the independent reference uses `O(N²K + NK(K+1)!)` time
because it rebuilds determinant inputs per cell, plus the `O(NK)` status
replay. Its bounded scratch is `O(NK+K³)`. The `1e-9` absolute and `1e-12` relative tolerances apply to
the pinned bounded fixtures, including the small nonzero-denominator case.

## Language ports

- [C](../../../c/w/wynn_epsilon_sequence_algorithm.c)
- [C3](../../../c3/w/wynn_epsilon_sequence_algorithm.c3)
- [C++](../../../cpp/w/wynn_epsilon_sequence_algorithm.cpp)
- [Elisa](../../../elisa/w/wynn_epsilon_sequence_algorithm.elisa)
- [Mojo](../../../mojo/w/wynn_epsilon_sequence_algorithm.mojo)
- [Nim](../../../nim/w/wynn_epsilon_sequence_algorithm.nim)
- [Odin](../../../odin/w/wynn_epsilon_sequence_algorithm.odin)
- [Rust](../../../rust/w/wynn_epsilon_sequence_algorithm.rs)
- [V](../../../v/w/wynn_epsilon_sequence_algorithm.v)
- [Zig](../../../zig/w/wynn_epsilon_sequence_algorithm.zig)

Fixture framing, successful output lengths, singular cases, and capacity
behavior are recorded in [`workload.json`](workload.json). No upstream code,
test material, or example fixtures are reused.

The package is registered in the `float64_slice_io` recorder and verifier, and
in the repository [catalog](../../../CATALOG.md).
