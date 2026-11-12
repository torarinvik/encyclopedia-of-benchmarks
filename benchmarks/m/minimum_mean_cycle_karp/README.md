# Karp minimum mean cycle

Return the exact minimum average edge weight among all directed cycles in a
bounded strongly connected graph. The primary implementation uses Karp's
minimum-cycle-mean characterization over shortest walk costs indexed by exact
path length.

## Contract

The exported symbol is
`minimum_mean_cycle_karp(input, length, output, capacity) -> i64` in the
`i64_array_bytes_output` ABI. The input is `[n,m,(u,v,weight)*m]`, with
`1<=n<=8`, `1<=m<=min(16,n*n)`, zero-based endpoints, and weights in `[-1000,1000]`.
The directed graph must be strongly connected and must have unique ordered
endpoint pairs; self-loops are allowed. The frame must contain exactly
`2+3*m` signed-i64 values; the maximum valid input has 50 values and the
longest parseable frame has 51. Null input,
malformed framing, duplicate edges, invalid weights/endpoints, or a graph that
is not strongly connected returns `-1` before output checks.

The output is exactly two signed little-endian i64 values:
`[reduced_numerator, positive_denominator]`. Their ratio is the minimum cycle
mean, reduced by the gcd; zero is `[0,1]`. The function returns 16 bytes. Null
output or capacity below 16 returns `-2` without writes. Workspace is bounded
at 2,048 bytes.

## Algorithm and verification

Fix source vertex 0. Let `F_k(v)` be the minimum weight of any directed walk
of exactly `k` edges from 0 to `v`, with `F_0(0)=0` and unreachable states
absent. For each edge `(u,v,w)`, the recurrence extends a reachable
`F_(k-1)(u)` by `w`. Karp's characterization gives the minimum cycle mean as
the minimum over vertices with finite `F_n(v)` of the maximum finite ratio
`(F_n(v)-F_k(v))/(n-k)` for `0<=k<n`. Rational comparisons use integer
cross-products, so negative and fractional means remain exact. The DP costs
`O(n*m+n^2)` time and `O(n^2+m)` space.

The independent oracle enumerates simple directed cycles, retaining each
cycle only from its least-numbered vertex, then compares `weight/length`
fractions by cross-products. A minimum-mean closed walk always contains a
simple cycle with no larger mean, so this enumeration checks the same
mathematical result through a different structure. Its exponential time is
bounded by `n<=8`.

[`negative_cycle_detection`](../../n/negative_cycle_detection/README.md)
reports whether any cycle has negative total weight and may return a witness;
Bellman–Ford and Johnson compute path distances. This package minimizes the
average weight over all cycles, which is a different objective. Its Karp
dynamic program is also distinct from Karp's TSP cycle-merging heuristic.

The [workload](workload.json) includes fractional means, a negative
self-loop, a maximum-input 8-vertex graph, disconnected input, duplicate edges,
invalid weights, null pointers, and capacity errors. The
[primary oracle](primary_oracle.py) follows Karp's DP formula; the
[independent oracle](independent_oracle.py) enumerates simple cycles.
`check_inventory.py` statically checks package metadata, workload bounds, all
ten language ports, and the Elisa safe-view requirement.

## Provenance

The algorithm is attributed to Richard M. Karp, “A characterization of the
minimum cycle mean in a digraph,” *Discrete Mathematics* 23(3), 1978,
[DOI 10.1016/0012-365X(78)90011-0](https://doi.org/10.1016/0012-365X(78)90011-0).
See [`RIGHTS.md`](RIGHTS.md) for the clean-room note.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/minimum_mean_cycle_karp.c`](../../../c/m/minimum_mean_cycle_karp.c) |
| C3 | [`c3/m/minimum_mean_cycle_karp.c3`](../../../c3/m/minimum_mean_cycle_karp.c3) |
| C++ | [`cpp/m/minimum_mean_cycle_karp.cpp`](../../../cpp/m/minimum_mean_cycle_karp.cpp) |
| Elisa | [`elisa/m/minimum_mean_cycle_karp.elisa`](../../../elisa/m/minimum_mean_cycle_karp.elisa) |
| Mojo | [`mojo/m/minimum_mean_cycle_karp.mojo`](../../../mojo/m/minimum_mean_cycle_karp.mojo) |
| Nim | [`nim/m/minimum_mean_cycle_karp.nim`](../../../nim/m/minimum_mean_cycle_karp.nim) |
| Odin | [`odin/m/minimum_mean_cycle_karp.odin`](../../../odin/m/minimum_mean_cycle_karp.odin) |
| Rust | [`rust/m/minimum_mean_cycle_karp.rs`](../../../rust/m/minimum_mean_cycle_karp.rs) |
| V | [`v/m/minimum_mean_cycle_karp.v`](../../../v/m/minimum_mean_cycle_karp.v) |
| Zig | [`zig/m/minimum_mean_cycle_karp.zig`](../../../zig/m/minimum_mean_cycle_karp.zig) |
