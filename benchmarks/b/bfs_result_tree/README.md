# Breadth-first search result tree

This package captures the richer result returned by the pinned Ruby BFS implementation: its `seen` and `visited` sets, plus parent and hop-distance maps. It uses a bounded directed adjacency list so input neighbor order deterministically controls first discovery and parent selection.

## Contract

- Input is `[vertex_count, edge_count, start_vertex, (from,to)...]` as signed 64-bit integers, with exact packing and no trailing fields.
- There are 1 through 32 vertices and 0 through 126 directed edges. Vertex IDs are zero-based and must be in range. Duplicate edges and self-loops are allowed. Each vertex's neighbors are processed in the order its outgoing edges appear in the input.
- BFS marks a vertex seen when it is first enqueued, sets its parent and hop distance at that point, and adds it to `visited` when it is dequeued. The root's parent is `-1` in the normalized output; its distance is 0.
- Output is a little-endian signed i64 vector:
  `[seen_count, seen_discovery_order..., visited_count, visited_dequeue_order..., parent_count, (node,parent)..., distance_count, (node,hop_distance)...]`.
  Parent and distance pairs follow discovery order. The function returns the output byte count.
- Malformed input returns `-1`; insufficient output capacity or a null output buffer returns `-2`.

The graph interface is normalized to directed adjacency because the source accepts any object with a `neighbors(node)` method. The returned sets and maps are represented as ordered sequences so edge-order-dependent parents remain observable. This package is separate from [`breadth_first_search`](../breadth_first_search/README.md), which returns only a traversal order and sorts neighbors by vertex ID.

## Pinned source

- [TheAlgorithms/Ruby `bfs.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/graphs/bfs.rb)

[`workload.json`](workload.json) covers input-order-dependent parents, cycles and unreachable nodes, duplicate edges, self-loops, an isolated root, and malformed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bfs_result_tree.c`](../../../c/b/bfs_result_tree.c) |
| C3 | [`c3/b/bfs_result_tree.c3`](../../../c3/b/bfs_result_tree.c3) |
| C++ | [`cpp/b/bfs_result_tree.cpp`](../../../cpp/b/bfs_result_tree.cpp) |
| Elisa | [`elisa/b/bfs_result_tree.elisa`](../../../elisa/b/bfs_result_tree.elisa) |
| Nim | [`nim/b/bfs_result_tree.nim`](../../../nim/b/bfs_result_tree.nim) |
| Odin | [`odin/b/bfs_result_tree.odin`](../../../odin/b/bfs_result_tree.odin) |
| Rust | [`rust/b/bfs_result_tree.rs`](../../../rust/b/bfs_result_tree.rs) |
| V | [`v/b/bfs_result_tree.v`](../../../v/b/bfs_result_tree.v) |
| Zig | [`zig/b/bfs_result_tree.zig`](../../../zig/b/bfs_result_tree.zig) |
