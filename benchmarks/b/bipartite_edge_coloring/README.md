# Bipartite Edge Coloring

Color every edge of a bipartite multigraph with the minimum possible number of
colors. The task follows the [Library Checker statement](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/bipartite_edge_coloring/task.md)
and [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/bipartite_edge_coloring/info.toml).
The ports and oracle are clean-room implementations.

## Contract

The `i64_array_bytes_output` input is `[L, R, M, (a, b)*M]`, where each edge
joins left vertex `a` to right vertex `b`. Official limits are `L,R,M <=
100000`; this local profile uses `1 <= L,R <= 5` and `1 <= M <= 10`.
Parallel edges are distinct and allowed. The output is `[K, c_0, ..., c_(M-1)]`
as unsigned 64-bit little-endian values. `K` must be the edge chromatic number
and the colors must be proper. By König's line-coloring theorem, `K` equals
the maximum degree. Invalid input returns `-1`; a null output or capacity
shortage returns `-2`. Validation precedes output errors, and failures write no
bytes.

## Algorithm and bounds

Pad the smaller side with isolated vertices, then add dummy parallel edges
until every vertex on both sides has degree `K`. Each regularized graph has a
perfect matching. Find one by deterministic augmenting paths, remove its edges,
and repeat for all `K` colors. When a matched pair still contains an original
edge, color the earliest uncolored input edge at that pair; otherwise that
matched edge is dummy. This decomposes the regularized graph into `K`
matchings and gives a proper `K`-edge-coloring of the original graph. The
bounded implementation uses `O(K * V * E)` time and `O(V^2 + E)` working
space.

This differs from the local Hopcroft–Karp and Kuhn packages, which produce one
maximum vertex matching. Edge coloring partitions the full multiset of edges
into the minimum number of matchings; local vertex-coloring packages color
vertices. The oracle independently checks framing and uses the same stable
matching rule to provide exact expected bytes; each result is also a
certificate that can be checked for `K = Δ` and no repeated color at a vertex.

See [`workload.json`](workload.json) and the bounded
[coloring oracle](../../bipartite_edge_coloring_oracle.py). No implementation
has been run or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/bipartite_edge_coloring.c`](../../../c/bipartite_edge_coloring.c) |
| C3 | [`c3/b/bipartite_edge_coloring.c3`](../../../c3/b/bipartite_edge_coloring.c3) |
| C++ | [`cpp/b/bipartite_edge_coloring.cpp`](../../../cpp/b/bipartite_edge_coloring.cpp) |
| Elisa | [`elisa/b/bipartite_edge_coloring.elisa`](../../../elisa/b/bipartite_edge_coloring.elisa) |
| Nim | [`nim/b/bipartite_edge_coloring.nim`](../../../nim/b/bipartite_edge_coloring.nim) |
| Odin | [`odin/b/bipartite_edge_coloring.odin`](../../../odin/b/bipartite_edge_coloring.odin) |
| Rust | [`rust/b/bipartite_edge_coloring.rs`](../../../rust/b/bipartite_edge_coloring.rs) |
| V | [`v/b/bipartite_edge_coloring.v`](../../../v/b/bipartite_edge_coloring.v) |
| Zig | [`zig/b/bipartite_edge_coloring.zig`](../../../zig/b/bipartite_edge_coloring.zig) |
| Mojo | [`mojo/b/bipartite_edge_coloring.mojo`](../../../mojo/b/bipartite_edge_coloring.mojo) |
