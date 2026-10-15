# BFS graph coloring

This package adapts Go's `Graph.ColorUsingBFS`, which colors graph vertices while traversing each component breadth first. It begins every vertex at color 1. When it examines an edge from the current vertex to a neighbor with the same color, it increments the neighbor's color, then queues that neighbor if it has not been visited. The returned `colors_used` is the maximum color assigned.

Go iterates each adjacency map in unspecified order. The contract uses a disjoint star forest, where that iteration order does not change the final vertex colors. This keeps the source's BFS and color increments observable without depending on map order.

## Contract

Input is a signed 64-bit array `[vertex_count, edge_count, (u, v)...]`. There are 0 through 64 vertices, labeled densely from 0. All vertices are present before edges are added. Edges are simple and undirected: endpoints must be distinct and in range, and an unordered pair may appear only once. Every connected component must be a star or an isolated vertex; equivalently, each component has at most one vertex with degree greater than one. The input must contain exactly `2 + 2 * edge_count` values. Invalid input returns `-1`.

Output is `[vertex_count, color_0, ..., color_(vertex_count-1), colors_used]`, encoded as little-endian signed 64-bit values. The function returns the output byte count. Insufficient or null output capacity returns `-2` without writing. An empty graph produces `[0, 0]`.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm bfs_graph_coloring --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/bfs_graph_coloring/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bfs_graph_coloring.c`](../../../c/b/bfs_graph_coloring.c) |
| C3 | [`c3/b/bfs_graph_coloring.c3`](../../../c3/b/bfs_graph_coloring.c3) |
| C++ | [`cpp/b/bfs_graph_coloring.cpp`](../../../cpp/b/bfs_graph_coloring.cpp) |
| Elisa | [`elisa/b/bfs_graph_coloring.elisa`](../../../elisa/b/bfs_graph_coloring.elisa) |
| Nim | [`nim/b/bfs_graph_coloring.nim`](../../../nim/b/bfs_graph_coloring.nim) |
| Odin | [`odin/b/bfs_graph_coloring.odin`](../../../odin/b/bfs_graph_coloring.odin) |
| Rust | [`rust/b/bfs_graph_coloring.rs`](../../../rust/b/bfs_graph_coloring.rs) |
| V | [`v/b/bfs_graph_coloring.v`](../../../v/b/bfs_graph_coloring.v) |
| Zig | [`zig/b/bfs_graph_coloring.zig`](../../../zig/b/bfs_graph_coloring.zig) |

## Pinned source

- Go [`bfs.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/bfs.go)
- Go graph structure [`graph.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/coloring/graph.go)
