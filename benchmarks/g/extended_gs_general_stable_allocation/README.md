# Extended-GS general stable allocation

This bounded profile runs the chapter's Extended-GS algorithm on a small
multi-unit allocation subclass. There are one or two men and one or two women.
Each person has a total dance-unit quota `T` of one or two, and a pair may
receive zero, one, or two units. Each person-edge value is separable and
concave: the input supplies its first and second marginal utilities, with the
second marginal no larger than the first. A person's utility is the sum of
these edge utilities on the domain whose total allocation does not exceed
`T`. This is a bounded laminar/separable concave subclass of the chapter's
`M♮`-concave functions.

Input is `[men,women,T,(man_first,man_second,woman_first,woman_second)*]`,
with edge records in row-major man/woman order. Marginals are integers in
`0..8`. The ports choose the lexicographically smallest maximizing allocation
at every Extended-GS maximization. They initialize `z_M` to infinity, and
initialize `z_W=x_W=0`; when `x_M(e)>x_W(e)`, they set `z_M(e)=x_W(e)` and
`z_W(e)=infinity`. The infinity output sentinel is `255`.

The output is little-endian signed-i64 data
`[edge_count,x_M[edge_count],z_M[edge_count],(z_W∨x_M)[edge_count]]`.
The `z_W∨x_M` vector is the componentwise maximum specified by the chapter.
The maximum input is 19 i64 values and the maximum output is 104 bytes.
Malformed input returns `-1`; null output or insufficient capacity returns
`-2` without writes.

The repeated-unit allocations and concave utility state make this distinct
from strict one-to-one [stable marriage](../stable_matching/README.md) and
many-to-one [hospitals/residents](../hospitals_residents_rgs/README.md). The
package implements only this bounded separable-concave subclass and does not
claim to handle arbitrary `M♮`-concave functions.

Source: “Stable Marriage and Discrete Convex Analysis,” Akihisa Tamura,
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_394`](https://doi.org/10.1007/978-1-4939-2864-4_394).
See [RIGHTS.md](RIGHTS.md) for attribution.

The primary oracle enumerates complete bounded allocations for each aggregate
maximization. The independent verifier optimizes person by person, then
executes Extended-GS with the same deterministic tie rule. The [workload]
(workload.json) includes repeated units, a bound-lowering step, interacting
quota constraints, and maximum framing.

| Language | Port |
|---|---|
| C | `c/g/extended_gs_general_stable_allocation.c` |
| C3 | `c3/g/extended_gs_general_stable_allocation.c3` |
| C++ | `cpp/g/extended_gs_general_stable_allocation.cpp` |
| Elisa | `elisa/g/extended_gs_general_stable_allocation.elisa` |
| Nim | `nim/g/extended_gs_general_stable_allocation.nim` |
| Odin | `odin/g/extended_gs_general_stable_allocation.odin` |
| Rust | `rust/g/extended_gs_general_stable_allocation.rs` |
| V | `v/g/extended_gs_general_stable_allocation.v` |
| Zig | `zig/g/extended_gs_general_stable_allocation.zig` |
