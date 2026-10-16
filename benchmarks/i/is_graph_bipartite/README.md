# Bipartite graph by BFS

This package ports the pinned C++ `Graph::is_bipartite` method. It assigns alternating sides with breadth-first search and checks every connected component of an undirected graph.

## Contract

- Input is a signed 64-bit array `[vertex_count, edge_count, (u, v)...]`. Vertex count is 0 through 64 and edge count is 0 through 256. A valid maximum-size input is 514 values; the workload's 516-value edge-count-over-limit case checks rejection just beyond that bound.
- Edge endpoints are one-based, matching `Graph::addEdge`; each pair adds an undirected edge. Repeated edges are allowed. Self-loops are valid and make the graph non-bipartite.
- Output is `1` for bipartite and `0` otherwise. Malformed input or an endpoint outside `1..vertex_count` returns `-1`.
- The return decision is independent of vertex coloring order; the package preserves the source's BFS strategy and checks disconnected components.

## Workload

[`workload.json`](workload.json) covers empty and disconnected graphs, paths, even and odd cycles, self-loops, repeated edges, dense graphs, input limits, and malformed endpoints and shapes.

Verify the available language implementations with the shared array-scalar verifier:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms is_graph_bipartite
```

## Pinned sources

- C++ [`is_graph_bipartite.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/is_graph_bipartite.cpp)
- Duplicate C++ copy [`is_graph_bipartite.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/is_graph_bipartite.cpp)

The related `is_graph_bipartite2` candidate uses the same BFS coloring decision with a different adjacency input shape and is suitable as an alias once its source-specific validation is recorded.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_graph_bipartite.c`](../../../c/i/is_graph_bipartite.c) |
| C3 | [`c3/i/is_graph_bipartite.c3`](../../../c3/i/is_graph_bipartite.c3) |
| C++ | [`cpp/i/is_graph_bipartite.cpp`](../../../cpp/i/is_graph_bipartite.cpp) |
| Elisa | [`elisa/i/is_graph_bipartite.elisa`](../../../elisa/i/is_graph_bipartite.elisa) |
| Nim | [`nim/i/is_graph_bipartite.nim`](../../../nim/i/is_graph_bipartite.nim) |
| Odin | [`odin/i/is_graph_bipartite.odin`](../../../odin/i/is_graph_bipartite.odin) |
| Rust | [`rust/i/is_graph_bipartite.rs`](../../../rust/i/is_graph_bipartite.rs) |
| V | [`v/i/is_graph_bipartite.v`](../../../v/i/is_graph_bipartite.v) |
| Zig | [`zig/i/is_graph_bipartite.zig`](../../../zig/i/is_graph_bipartite.zig) |
