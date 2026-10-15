# Connected components with depth first search

Count the connected components in an undirected graph. The pinned C++ implementation adds each edge in both directions, then scans every vertex and starts recursive depth first search from each unvisited vertex. This counts isolated vertices as components.

## Contract

- The `i64_array_scalar` input is `[n, m, u_0, v_0, ..., u_(m-1), v_(m-1)]`.
- `n` is 0..256, `m` is 0..512, endpoints are 1-based values in 1..n, and the packed array has exactly `2 + 2*m` values.
- Return the number of connected components. When `n=0,m=0`, return 0. Duplicate edges and self-loops are valid and do not change the component count.
- Invalid shape, bounds, or endpoint values return `-1`.
- The ports store the undirected graph in a bounded adjacency matrix and run DFS from every unvisited vertex. This preserves the source's traversal/count behavior while keeping the ABI input as an edge list.

## Source and related algorithms

The canonical source is the pinned C++ [`connected_components.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/connected_components.cpp); the second C++ repository contains the same candidate path. The source maps input endpoint `u` to adjacency index `u-1`, inserts both directed adjacency entries, and recursively explores neighbors. [`connected_components_with_dsu`](../connected_components_with_dsu/README.md) counts components with a disjoint-set union structure, so it remains a separate algorithm benchmark.

[`workload.json`](workload.json) covers the empty graph, isolated vertices, both source examples, disconnected clusters, repeated edges, self-loops, and malformed input. The shared `i64_array_scalar` ABI returns the component count directly. The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

| Language | Source |
| --- | --- |
| C | [`c/c/connected_components.c`](../../../c/c/connected_components.c) |
| C3 | [`c3/c/connected_components.c3`](../../../c3/c/connected_components.c3) |
| C++ | [`cpp/c/connected_components.cpp`](../../../cpp/c/connected_components.cpp) |
| Elisa | [`elisa/c/connected_components.elisa`](../../../elisa/c/connected_components.elisa) |
| Nim | [`nim/c/connected_components.nim`](../../../nim/c/connected_components.nim) |
| Odin | [`odin/c/connected_components.odin`](../../../odin/c/connected_components.odin) |
| Rust | [`rust/c/connected_components.rs`](../../../rust/c/connected_components.rs) |
| V | [`v/c/connected_components.v`](../../../v/c/connected_components.v) |
| Zig | [`zig/c/connected_components.zig`](../../../zig/c/connected_components.zig) |
