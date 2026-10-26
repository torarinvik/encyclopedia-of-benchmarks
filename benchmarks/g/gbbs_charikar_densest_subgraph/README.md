# GBBS Charikar approximate densest subgraph

This package is a bounded deterministic projection of GBBS's
`GreedyCharikar/DensestSubgraph.h::CharikarAppxDensestSubgraph`, using the
same `KCore.h::DegeneracyOrder` shell-peeling helper. It returns the maximum
average degree among the induced suffixes of that order. This is Charikar's
2-approximation profile; it is distinct from exact maximum-clique, core-number,
and other graph-density objectives.

The input is `[n, m, (u, v)...]`, with each simple undirected edge supplied
once in canonical order `u < v`. Bounds are `1 <= n <= 16` and `0 <= m <= 64`.
The implementation peels each minimum residual-degree shell together, orders
ties by vertex ID, clamps surviving residual degrees to the shell value, then
computes the source's suffix score `2 * induced_edges / remaining_vertices`.
Isolates and disconnected graphs are supported. Malformed inputs return
`-1e300`.

All nine ports use the `i64_array_float64` ABI. The package oracle and a
separate verifier oracle are provided. The pinned source is
[`GreedyCharikar/DensestSubgraph.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/ApproximateDensestSubgraph/GreedyCharikar/DensestSubgraph.h)
and its peeling helper is
[`KCore.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/KCore/JulienneDBS17/KCore.h).
See `workload.json` for fixtures and source bounds. The full GBBS MIT notice is
included in `LICENSE.txt`.

## Language ports

[C](../../../c/g/gbbs_charikar_densest_subgraph.c) ·
[C3](../../../c3/g/gbbs_charikar_densest_subgraph.c3) ·
[C++](../../../cpp/g/gbbs_charikar_densest_subgraph.cpp) ·
[Elisa](../../../elisa/g/gbbs_charikar_densest_subgraph.elisa) ·
[Nim](../../../nim/g/gbbs_charikar_densest_subgraph.nim) ·
[Odin](../../../odin/g/gbbs_charikar_densest_subgraph.odin) ·
[Rust](../../../rust/g/gbbs_charikar_densest_subgraph.rs) ·
[V](../../../v/g/gbbs_charikar_densest_subgraph.v) ·
[Zig](../../../zig/g/gbbs_charikar_densest_subgraph.zig)
