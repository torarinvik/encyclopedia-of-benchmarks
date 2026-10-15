# 0-1 BFS shortest paths

This benchmark computes shortest distances from one source in a directed graph whose edge weights are restricted to 0 or 1. The pinned Java source uses a deque: a successful relaxation over a zero-weight edge pushes the neighbor to the front, and a one-weight edge pushes it to the back. This is distinct from [`bfs_queue`](../../b/bfs_queue/README.md), which finds an unweighted path in an undirected graph, and [`dijkstra`](../../d/dijkstra/README.md), which supports arbitrary nonnegative weights and reports distances with a separate reachability vector.

## Contract

- Input is `[vertex_count, source, edge_count, (origin, destination, weight) * edge_count]`.
- Graphs contain 1–64 vertices and 0–1,024 directed edges. Packed input length is exactly `3 + 3 * edge_count` and is at most 3,075 signed 64-bit values.
- Vertex IDs are zero-based. Every edge endpoint must be in range and every weight must be 0 or 1. Self-edges and parallel edges are allowed; duplicate edges of the same weight are coalesced.
- The output is one byte per vertex in vertex-ID order. A reachable vertex stores its shortest distance; byte value 255 marks an unreachable vertex. A finite shortest path can be made simple, so its distance is at most 63.
- On success, return the vertex count. Invalid input returns -1; insufficient output capacity returns -2. Errors write no output.

All ports use fixed-size adjacency bitsets and a circular deque. They process zero-weight neighbors at the front and one-weight neighbors at the back, updating a vertex only when its distance strictly improves. The output contains distances only, so equal-cost path tie order is not observable.

The Java source returns `Integer.MAX_VALUE` for unreachable vertices, throws for an invalid source, and throws when traversal encounters a non-binary edge weight. The benchmark maps unreachable entries to 255 and invalid packed inputs to -1; it validates all endpoints and weights before traversal. The source also skips null/malformed adjacency entries and silently ignores out-of-range neighbors. The flat input cannot express null or malformed edge records, and it maps an encoded out-of-range endpoint to invalid input.

## Workload and build

[`workload.json`](workload.json) covers zero- and one-weight paths, alternate routes, directed and disconnected graphs, cycles, parallel edges, invalid inputs, and maximum vertex and edge bounds. Build and record with the `i64_array_bytes_output` ABI family.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm zero_one_bfs --language c
python3 benchmarks/run_i64_array_bytes_output.py \
  --build-manifest build/i64_array_bytes_output/z/zero_one_bfs/c/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/z/zero_one_bfs.c`](../../../c/z/zero_one_bfs.c) |
| C3 | [`c3/z/zero_one_bfs.c3`](../../../c3/z/zero_one_bfs.c3) |
| C++ | [`cpp/z/zero_one_bfs.cpp`](../../../cpp/z/zero_one_bfs.cpp) |
| Elisa | [`elisa/z/zero_one_bfs.elisa`](../../../elisa/z/zero_one_bfs.elisa) |
| Nim | [`nim/z/zero_one_bfs.nim`](../../../nim/z/zero_one_bfs.nim) |
| Odin | [`odin/z/zero_one_bfs.odin`](../../../odin/z/zero_one_bfs.odin) |
| Rust | [`rust/z/zero_one_bfs.rs`](../../../rust/z/zero_one_bfs.rs) |
| V | [`v/z/zero_one_bfs.v`](../../../v/z/zero_one_bfs.v) |
| Zig | [`zig/z/zero_one_bfs.zig`](../../../zig/z/zero_one_bfs.zig) |

## Source

- [TheAlgorithms Java `ZeroOneBfs.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/ZeroOneBfs.java)
