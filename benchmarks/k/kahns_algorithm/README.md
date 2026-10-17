# Kahn's topological sort

This package ports the pinned Java `TopologicalSort.topSortOrder` implementation. It is separate from the existing Go `kahn` benchmark: the Go contract returns only the processed-vertex count, declares vertices explicitly, and coalesces duplicate edges; this package returns the ordered endpoint labels and preserves duplicate edges.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[edge_count, from_0, to_0, ..., from_(m-1), to_(m-1)]`, with exact length `1 + 2*edge_count` and `0 <= edge_count <= 128`.
- Every endpoint must fit signed i32. The vertex set is inferred from endpoints, in first-seen order; at most 32 distinct vertices are allowed. Isolated vertices cannot be represented. An edge count of zero defines the empty graph.
- Parallel edges are preserved and each copy contributes to in-degree and is removed during Kahn processing. A self-edge is a cycle.
- Accept only graphs with a unique topological ordering: at every Kahn step there must be exactly one currently available zero-in-degree vertex. Cycles and DAGs with more than one available vertex at any step return `-1`.
- Successful output contains the topological order as little-endian signed-i32 labels, and returns `4*vertex_count` bytes (maximum 128). Empty graph output is zero bytes and returns `0` with a nonnull output pointer and zero capacity.
- Malformed input, out-of-range labels, too many vertices or edges, cycles, and non-unique orders return `-1` before output storage is checked. Null output or insufficient capacity returns `-2` without writes, including for the empty graph.

The Java source stores adjacency lists in insertion order but initializes its Kahn queue by iterating a `HashMap` of in-degrees. Restricting the workload to unique orders removes that unspecified tie order. Repeated edges stay in each adjacency list and are counted individually.

The ports store each outgoing edge in an insertion-ordered linked array and process only the current vertex's outgoing edges during Kahn traversal. This keeps the traversal O(V+E) and preserves parallel edges. Fixed-array ports intern endpoint labels with a bounded linear search over at most 32 vertices.

## Workload and source

[`workload.json`](workload.json) covers the empty graph, a unique chain, duplicate edges, signed-i32 endpoint boundaries, the 32-vertex and 128-edge limits, ambiguous DAGs, cycles, malformed records, and output capacity errors. The independent [oracle](../../kahns_algorithm_oracle.py) returns the ordered labels as little-endian bytes.

Pinned source: [TheAlgorithms/Java `KahnsAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/KahnsAlgorithm.java), method `TopologicalSort.topSortOrder`.

| Language | Port |
|---|---|
| C | [`c/k/kahns_algorithm.c`](../../../c/kahns_algorithm.c) |
| C3 | [`c3/k/kahns_algorithm.c3`](../../../c3/kahns_algorithm.c3) |
| C++ | [`cpp/k/kahns_algorithm.cpp`](../../../cpp/kahns_algorithm.cpp) |
| Elisa | [`elisa/k/kahns_algorithm.elisa`](../../../elisa/kahns_algorithm.elisa) |
| Nim | [`nim/k/kahns_algorithm.nim`](../../../nim/kahns_algorithm.nim) |
| Odin | [`odin/k/kahns_algorithm.odin`](../../../odin/kahns_algorithm.odin) |
| Rust | [`rust/k/kahns_algorithm.rs`](../../../rust/k/kahns_algorithm.rs) |
| V | [`v/k/kahns_algorithm.v`](../../../v/kahns_algorithm.v) |
| Zig | [`zig/k/kahns_algorithm.zig`](../../../zig/kahns_algorithm.zig) |
