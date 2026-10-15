# A* weighted graph search (Java variant)

This benchmark ports the pinned [TheAlgorithms/Java `AStar.aStar`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/AStar.java). The graph is undirected and weighted. Each queued candidate carries its accumulated distance, the caller-supplied heuristic for its endpoint, and its full path. Expansion rejects a neighbor only when that vertex already appears in the current path; the source has no global visited set or best-distance table.

## Contract

- Input is `[node_count, edge_count, start, target, heuristic[0..node_count), edge triples...]`. Node count is 1..7, edge count 0..16, heuristic values -1000..1000, and edge weights 0..1000.
- The graph is simple and undirected: self-loops and repeated unordered edges are invalid. Each edge is stored in both directions, preserving the input order in each adjacency list. The source's Java fixture supplies four-slot records `[u,v,w,null]`, but `initializeGraph` consumes only the first three values; the benchmark ABI omits that unused fourth slot.
- The queue is ordered by `distance + heuristic`, preserving Java `PriorityQueue` binary-heap insertion and poll behavior for ties. Nonnegative bounded edge weights keep all path sums finite and within the Java `int` domain.
- On success, output is `[distance, heuristic_at_target, path_length, path_vertices...]`, encoded as signed i64 little-endian words. If no path exists, output is `[-1,-1,0]`. Return value is the byte count. Invalid input returns `-1`; insufficient capacity returns `-2` without output.
- The path-simple search has a bounded state space. With at most seven vertices and no repeated vertices, there are at most 1,957 distinct partial paths from a start vertex; a 4,096-state workspace covers the full documented graph domain.

[`workload.json`](workload.json) includes the upstream five-node fixture, weighted and zero-weight paths, a disconnected target, a same-node query, invalid packing, and insufficient capacity.

## Workload and build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm astar_java_weighted_graph --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/a/astar_java_weighted_graph/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/a/astar_java_weighted_graph.c`](../../../c/a/astar_java_weighted_graph.c) |
| C3 | [`c3/a/astar_java_weighted_graph.c3`](../../../c3/a/astar_java_weighted_graph.c3) |
| C++ | [`cpp/a/astar_java_weighted_graph.cpp`](../../../cpp/a/astar_java_weighted_graph.cpp) |
| Elisa | [`elisa/a/astar_java_weighted_graph.elisa`](../../../elisa/a/astar_java_weighted_graph.elisa) |
| Nim | [`nim/a/astar_java_weighted_graph.nim`](../../../nim/a/astar_java_weighted_graph.nim) |
| Odin | [`odin/a/astar_java_weighted_graph.odin`](../../../odin/a/astar_java_weighted_graph.odin) |
| Rust | [`rust/a/astar_java_weighted_graph.rs`](../../../rust/a/astar_java_weighted_graph.rs) |
| V | [`v/a/astar_java_weighted_graph.v`](../../../v/a/astar_java_weighted_graph.v) |
| Zig | [`zig/a/astar_java_weighted_graph.zig`](../../../zig/a/astar_java_weighted_graph.zig) |
