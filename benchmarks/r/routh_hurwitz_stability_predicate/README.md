# Routh–Hurwitz stability predicate

This package checks whether a small real polynomial has all roots strictly
inside the open left half-plane. It works from the descending coefficient
array and uses exact arithmetic; it does not approximate or calculate the
roots.

## Contract

The exported scalar function is `routh_hurwitz_stability_predicate` in the
`i64_array_scalar` ABI family. Its complete input is
`[degree, a0, a1, ..., an]`, representing
`a0*s^degree + a1*s^(degree-1) + ... + an`. The degree is 1 through 4, each
coefficient is an integer in `[-3, 3]`, and the leading coefficient is in
`[1, 3]`.

Return `1` exactly when every root has a strictly negative real part. Return
`0` for a valid polynomial that is unstable or has a root on the imaginary
axis. A zero first-column pivot or an entire zero row in the Routh table returns
`0`; the profile does not use epsilon substitution or count roots in such
degenerate cases. Return `-1` for null, malformed, or out-of-profile input.
This predicate makes no claim about non-strict stability.

The primary reference constructs the rational Routh table using Python
fractions. Native ports use an equivalent fraction-free tableau: they omit the
division by the preceding pivot when forming each row. Relative to the
rational table, this scales the stored row by a product of prior pivots. The
profile continues only while those pivots are positive, so this positive row
scaling preserves every first-column sign. If any pivot is nonpositive, the
result is already false for strict stability and the recurrence stops. With
degree at most four and coefficient magnitude at most three, the largest
native scaled-table entry and product intermediate are at most 729. Each port
uses a fixed 5-by-3 integer table and a five-element coefficient array; the
declared workspace cap is 1,024 bytes.

The local [`polynomial_root_finding`](../polynomial_root_finding/README.md)
package estimates root locations numerically, while
[`durand_kerner_roots`](../durand_kerner_roots/README.md) iterates complex
root estimates. Neither implements this exact coefficient-only stability
predicate. Polynomial interpolation, factorization, and characteristic
polynomial packages likewise perform different operations.

## Sources and workload

The Routh-table method is grounded in Edward John Routh's 1877 treatise,
[*A Treatise on the Stability of a Given State of Motion*](https://archive.org/details/treatiseonstabil00routuoft).
The criterion is cross-checked against Adolf Hurwitz's original paper,
[“Über die Bedingungen, unter welchen eine Gleichung nur Wurzeln mit negativen reellen Theilen besitzt”](https://doi.org/10.1007/BF01446812),
and the [Encyclopedia of Mathematics entry](https://encyclopediaofmath.org/wiki/Routh-Hurwitz_criterion),
which states the equivalent positivity test for the leading principal Hurwitz
minors. The pinned RosettaCodeData [popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used only to discover the title at score 8. No task code, wording,
examples, or tests were reused.

The independent reference forms the Hurwitz matrix and expands its leading
principal determinants, a structurally different calculation from the Routh
recurrence. Workload fixtures include stable, unstable, repeated-root,
marginal, zero-pivot, zero-row, malformed, and null-input cases. Fixture
values are hand-derived. The package-local static workload and inventory
helpers were authored but not run.

## Native ports

| Language | Source |
|---|---|
| C | [`routh_hurwitz_stability_predicate.c`](../../../c/r/routh_hurwitz_stability_predicate.c) |
| C3 | [`routh_hurwitz_stability_predicate.c3`](../../../c3/r/routh_hurwitz_stability_predicate.c3) |
| C++ | [`routh_hurwitz_stability_predicate.cpp`](../../../cpp/r/routh_hurwitz_stability_predicate.cpp) |
| Elisa | [`routh_hurwitz_stability_predicate.elisa`](../../../elisa/r/routh_hurwitz_stability_predicate.elisa) |
| Mojo | [`routh_hurwitz_stability_predicate.mojo`](../../../mojo/r/routh_hurwitz_stability_predicate.mojo) |
| Nim | [`routh_hurwitz_stability_predicate.nim`](../../../nim/r/routh_hurwitz_stability_predicate.nim) |
| Odin | [`routh_hurwitz_stability_predicate.odin`](../../../odin/r/routh_hurwitz_stability_predicate.odin) |
| Rust | [`routh_hurwitz_stability_predicate.rs`](../../../rust/r/routh_hurwitz_stability_predicate.rs) |
| V | [`routh_hurwitz_stability_predicate.v`](../../../v/r/routh_hurwitz_stability_predicate.v) |
| Zig | [`routh_hurwitz_stability_predicate.zig`](../../../zig/r/routh_hurwitz_stability_predicate.zig) |

See [RIGHTS.md](RIGHTS.md), [INVENTORY.md](INVENTORY.md), and
[`INVENTORY.json`](INVENTORY.json) for provenance and the package file list.
The package is registered in the shared scalar runner and verifier, README,
catalog, and coverage ledger.
