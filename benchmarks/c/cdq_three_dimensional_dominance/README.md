# CDQ 3D dominance counts

This benchmark computes, for every input point, how many other input points
are no greater in any of the three coordinates. It uses CDQ divide and
conquer with a Fenwick tree for the third-coordinate prefix counts. Its
`i64_array_scalar` result is a weighted checksum of all per-point counts.

## Contract

Input is `[N,(x,y,z)*N]`, with `1<=N<=64` and every coordinate in
`[-1000,1000]`. For point `i`, the count includes each other input index `j`
such that `x[j]<=x[i]`, `y[j]<=y[i]`, and `z[j]<=z[i]`. Identical triples
count separately by input multiplicity, but a point does not count itself.
The scalar output is `sum((i+1)*count[i])`, with zero-based `i`. Invalid
framing, null input, or coordinates outside the bound return `-1`. Maximum
valid and parseable lengths are 193 and 194 i64 words. The declared workspace
is 8192 bytes.

The primary groups equal triples and sorts the groups lexicographically.
CDQ recursion counts each earlier-to-later pair once. Each half returns in
`y` order; the cross step inserts source groups with `y` no greater than each
target, queries a multiplicity-weighted Fenwick prefix in compressed `z`, and
merges the halves by `y`. The independent
oracle scans every ordered pair of original input points directly. For `U`
unique triples, the ports use bounded comparison loops to sort points and
compress z values in `O(U^2)` worst-case time; the CDQ/Fenwick counting phase
is `O(U log^2 U)` after that setup. The direct oracle is `O(N^2)`. The maximum
result is 131040, attained when all 64 points are identical.

This differs from [`pareto_optimization`](../../p/pareto_optimization/README.md),
which returns nondominated rows rather than per-point weak-dominance counts.
The local [`fenwick_tree`](../../f/fenwick_tree/README.md) is only the
underlying data structure.

## Provenance

The high-level method is described by [OI Wiki — CDQ Divide and Conquer](https://www.timothywang.ca/OI-wiki/misc/cdq-divide/), in its 3D partial-order example. OI Wiki's default content terms are CC BY-SA 4.0 and SATA; this package uses the algorithm description only. The operation profile, implementations, fixtures, and oracles are clean-room work; no source code, article prose, task text, or examples were copied. See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the two oracles, and the static inventory checker.

## Language ports

| Language | Source |
|---|---|
| C | [`c/cdq_three_dimensional_dominance.c`](../../../c/cdq_three_dimensional_dominance.c) |
| C3 | [`c3/cdq_three_dimensional_dominance.c3`](../../../c3/cdq_three_dimensional_dominance.c3) |
| C++ | [`cpp/cdq_three_dimensional_dominance.cpp`](../../../cpp/cdq_three_dimensional_dominance.cpp) |
| Elisa | [`elisa/cdq_three_dimensional_dominance.elisa`](../../../elisa/cdq_three_dimensional_dominance.elisa) |
| Mojo | [`mojo/cdq_three_dimensional_dominance.mojo`](../../../mojo/cdq_three_dimensional_dominance.mojo) |
| Nim | [`nim/cdq_three_dimensional_dominance.nim`](../../../nim/cdq_three_dimensional_dominance.nim) |
| Odin | [`odin/cdq_three_dimensional_dominance.odin`](../../../odin/cdq_three_dimensional_dominance.odin) |
| Rust | [`rust/cdq_three_dimensional_dominance.rs`](../../../rust/cdq_three_dimensional_dominance.rs) |
| V | [`v/cdq_three_dimensional_dominance.v`](../../../v/cdq_three_dimensional_dominance.v) |
| Zig | [`zig/cdq_three_dimensional_dominance.zig`](../../../zig/cdq_three_dimensional_dominance.zig) |
