# Borůvka minimum spanning tree

Find the minimum total weight of a spanning tree in a small connected, undirected weighted graph by repeatedly choosing the cheapest outgoing edge for each current component.

## Contract

- `i64_array_scalar` input is `[vertex_count, edge_count, (u, v, weight)*edge_count]`.
- Vertex count is 2..16. Edge count is `vertex_count - 1` through `min(64, vertex_count*(vertex_count - 1)/2)`. Packed length must be exactly `2 + 3*edge_count`.
- Endpoints use 1-based IDs. The graph must be connected and simple: no self-loops and no repeated unordered vertex pair. Weights are integers in 1..100; positive weights match the source's use of 0 as “no edge.”
- Return the MST total weight, at most 1,500, or -1 for malformed or disconnected input.

## Source semantics

The pinned C++ source builds a symmetric adjacency matrix, starts with one component per vertex, and on each Borůvka round selects the minimum outgoing edge for every component before unioning endpoints. The scalar result is the sum of the upper triangle of the resulting MST matrix. The ports preserve this component-wise edge-selection process and use the packed edge list as the common input representation. Ties are resolved deterministically by scanning matrix pairs in ascending vertex order. The source assumes connected input; the ports return -1 for disconnected graphs rather than entering a non-progressing round. This is Borůvka's algorithm, distinct from the Kruskal and Prim benchmarks.

## Workload

[`workload.json`](workload.json) covers a weighted triangle, a tree, equal-weight ties, the smallest graph, disconnected input, malformed lengths, duplicate edges, self-loops, and invalid weights. The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Pinned sources

- [C++ `boruvkas_minimum_spanning_tree.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/boruvkas_minimum_spanning_tree.cpp)
- [Duplicate C++ source in C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/greedy_algorithms/boruvkas_minimum_spanning_tree.cpp)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/boruvkas_minimum_spanning_tree.c`](../../../c/b/boruvkas_minimum_spanning_tree.c) |
| C3 | [`c3/b/boruvkas_minimum_spanning_tree.c3`](../../../c3/b/boruvkas_minimum_spanning_tree.c3) |
| C++ | [`cpp/b/boruvkas_minimum_spanning_tree.cpp`](../../../cpp/b/boruvkas_minimum_spanning_tree.cpp) |
| Elisa | [`elisa/b/boruvkas_minimum_spanning_tree.elisa`](../../../elisa/b/boruvkas_minimum_spanning_tree.elisa) |
| Nim | [`nim/b/boruvkas_minimum_spanning_tree.nim`](../../../nim/b/boruvkas_minimum_spanning_tree.nim) |
| Odin | [`odin/b/boruvkas_minimum_spanning_tree.odin`](../../../odin/b/boruvkas_minimum_spanning_tree.odin) |
| Rust | [`rust/b/boruvkas_minimum_spanning_tree.rs`](../../../rust/b/boruvkas_minimum_spanning_tree.rs) |
| V | [`v/b/boruvkas_minimum_spanning_tree.v`](../../../v/b/boruvkas_minimum_spanning_tree.v) |
| Zig | [`zig/b/boruvkas_minimum_spanning_tree.zig`](../../../zig/b/boruvkas_minimum_spanning_tree.zig) |
