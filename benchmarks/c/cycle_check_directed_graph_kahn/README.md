# Directed graph cycle check (Kahn's algorithm)

This benchmark checks for a directed cycle by repeatedly removing zero-indegree vertices. If fewer than all declared vertices can be removed, the remaining graph contains a cycle.

## Contract

- Input is a signed 64-bit array encoded as `[vertex_count, source_0, destination_0, ...]`.
- Graphs contain 0–64 vertices and at most 32 directed edges. Vertices are numbered from `0` through `vertex_count - 1`; isolated vertices are included by the vertex count.
- Duplicate edges are coalesced. A self-loop is a cycle. Disconnected components are all examined.
- Return `1` when a cycle exists, `0` when the graph is acyclic, and `-1` for malformed input or an endpoint outside the declared vertex range.
- Implementations use bounded, fixed-size adjacency bitsets and portable scalar operations. The queue begins with zero-indegree vertices in ascending ID order and scans neighbors in ascending ID order. This representation gives the bounded ports an `O(V²)` worst-case cost, with `V ≤ 64`.

The pinned C++ `isCyclicBFS` method uses Kahn's zero-indegree queue. The two pinned C++ repositories contain the same implementation. The source's depth-first variant is benchmarked separately in [`cycle_check_directed_graph`](../cycle_check_directed_graph/README.md).

## Workload

[`workload.json`](workload.json) is the same graph corpus used by the depth-first benchmark, so the two cycle-check strategies receive the same inputs, including maximum vertex and edge counts. Build with the `i64_array_scalar` ABI family.

## Reviewed TheAlgorithms sources

- [C++ `cycle_check_directed_graph.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/cycle_check_directed_graph.cpp)
- [C++ additional-repository mirror](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/cycle_check_directed_graph.cpp)
