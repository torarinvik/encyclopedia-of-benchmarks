# Connected undirected BFS visit order

This benchmark traverses a connected undirected graph with breadth-first search and returns the complete visitation order. The shared source families are C, Julia, and Swift. External vertex IDs are zero-based. The start vertex is fixed at 0: the pinned Swift example has no start parameter and begins from vertex 1, so the adapter maps external vertex 0 to that source vertex. Requiring connectivity makes its full-component traversal agree with the C and Julia traversals from the chosen start.

## Contract

Input is a signed 64-bit vector `[vertex_count, edge_count, start_vertex, (left, right)...]`. The vertex count is 1 through 40, edge count is 0 through 780, and `start_vertex` must be 0. Every edge is undirected and both endpoints must be in `[0, vertex_count)`. Repeated edges and self-loops are accepted and coalesced. The graph must be connected. Neighbors are visited in ascending vertex ID order, regardless of edge input order.

Output contains exactly `vertex_count` little-endian signed 64-bit vertex IDs in BFS visitation order. The return value is the number of visited vertices. Malformed or disconnected input returns `-1`; null or insufficient output capacity returns `-2` without writing output.

The workload includes a single vertex, paths, branching, cycles, self-loops, duplicate edges, maximum vertex and edge counts, disconnected input, and malformed traces. The pinned C implementation uses a 40-vertex queue; the limit matches it. The Julia adapter inserts each undirected edge in both adjacency lists, while the Swift adapter shifts labels by one to match its source's one-based nodes.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm bfs_connected_undirected_visit_order --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/bfs_connected_undirected_visit_order/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bfs_connected_undirected_visit_order.c`](../../../c/b/bfs_connected_undirected_visit_order.c) |
| C3 | [`c3/b/bfs_connected_undirected_visit_order.c3`](../../../c3/b/bfs_connected_undirected_visit_order.c3) |
| C++ | [`cpp/b/bfs_connected_undirected_visit_order.cpp`](../../../cpp/b/bfs_connected_undirected_visit_order.cpp) |
| Elisa | [`elisa/b/bfs_connected_undirected_visit_order.elisa`](../../../elisa/b/bfs_connected_undirected_visit_order.elisa) |
| Nim | [`nim/b/bfs_connected_undirected_visit_order.nim`](../../../nim/b/bfs_connected_undirected_visit_order.nim) |
| Odin | [`odin/b/bfs_connected_undirected_visit_order.odin`](../../../odin/b/bfs_connected_undirected_visit_order.odin) |
| Rust | [`rust/b/bfs_connected_undirected_visit_order.rs`](../../../rust/b/bfs_connected_undirected_visit_order.rs) |
| V | [`v/b/bfs_connected_undirected_visit_order.v`](../../../v/b/bfs_connected_undirected_visit_order.v) |
| Zig | [`zig/b/bfs_connected_undirected_visit_order.zig`](../../../zig/b/bfs_connected_undirected_visit_order.zig) |

## Pinned source references

- C: [`bfs.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/graphs/bfs.c)
- Julia: [`bfs.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/graph/bfs.jl)
- Swift: [`BFS.swift`](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/graph/BFS/BFS.swift)
