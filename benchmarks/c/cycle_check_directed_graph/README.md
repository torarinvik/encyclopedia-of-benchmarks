# Directed graph cycle check (depth-first search)

This benchmark reports whether a directed graph contains a cycle using depth-first search and three vertex states: unseen, on the active search path, and fully explored. An edge to a vertex on the active path proves a cycle.

## Contract

- Input is a signed 64-bit array encoded as `[vertex_count, source_0, destination_0, ...]`.
- Graphs contain 0–64 vertices and at most 32 directed edges. Vertices are numbered from `0` through `vertex_count - 1`; isolated vertices are included by the vertex count.
- Duplicate edges are coalesced. A self-loop is a cycle. Disconnected components are all examined.
- Return `1` when a cycle exists, `0` when the graph is acyclic, and `-1` for malformed input or an endpoint outside the declared vertex range.
- Implementations use bounded, fixed-size adjacency bitsets and portable scalar operations. Scanning possible neighbors gives these bounded ports an `O(V²)` worst-case cost, with `V ≤ 64`.

The pinned Go `HasCycle` method and C++ `isCyclicDFS` method use the same three-state depth-first cycle check. The Go graph must be directed for this contract; its default graph mode inserts reverse edges and would otherwise report undirected parent edges as cycles. The C++ source's separate Kahn implementation is benchmarked in [`cycle_check_directed_graph_kahn`](../cycle_check_directed_graph_kahn/README.md).

## Workload

[`workload.json`](workload.json) covers empty and isolated graphs, chains, disconnected components, self-loops, directed cycles with tails, duplicate edges, maximum vertex and edge counts, malformed encodings, and invalid endpoints. Build with the `i64_array_scalar` ABI family.

## Reviewed TheAlgorithms sources

- [Go `cycle.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/cycle.go)
- [C++ `cycle_check_directed_graph.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/cycle_check_directed_graph.cpp)
- [C++ additional-repository mirror](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/cycle_check_directed_graph.cpp)
