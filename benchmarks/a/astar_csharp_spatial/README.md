# A* spatial-tree search (C# variant)

This package maps the pinned [TheAlgorithms/C-Sharp `AStar.Compute`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/AStar/AStar.cs) with its `Node`, `VecN`, and list-based `PriorityQueue` support types. Nodes have spatial coordinates, a traversability flag, and a traversal-cost multiplier. The heuristic is Euclidean distance to the target.

## Contract

Input is `[node_count, edge_count, start, target, node_records..., directed_edges...]`. Each node record is `[x, y, traversable, traversal_multiplier]`; each edge is `[from, to]`. The graph is a directed rooted tree: `node_count` is 2..16, `edge_count` is exactly `node_count-1`, `start` is the root, every other node has one parent, and every node is reachable from the root. Coordinates are unique integer points with each coordinate in -1000..1000. Traversability is 0 or 1 and each multiplier is an integer from 1 through 4. The edge record order is the source adjacency order.

The tree restriction keeps the source's first-discovery path behavior and avoids its revisit/update branch. The ports preserve its binary min-heap tie behavior and the source's separate initialization of the root's neighbors. That initialization does not set their parent, so returned multi-node paths omit the start; a direct-child target is returned as a one-node path. `start == target` returns an empty path because `Compute` does not check the start node before seeding its neighbors. A blocked or otherwise unreachable target also returns an empty path.

Successful output is the returned path's node IDs as little-endian signed 64-bit values; the function returns the output byte length. Invalid input returns `-1`, and an insufficient or null output buffer for a nonempty path returns `-2`.

Pinned supporting source files: [`Node.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/AStar/Node.cs), [`VecN.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/AStar/VecN.cs), and [`PriorityQueue.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Search/AStar/PriorityQueue.cs).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/astar_csharp_spatial.c`](../../../c/a/astar_csharp_spatial.c) |
| C3 | [`c3/a/astar_csharp_spatial.c3`](../../../c3/a/astar_csharp_spatial.c3) |
| C++ | [`cpp/a/astar_csharp_spatial.cpp`](../../../cpp/a/astar_csharp_spatial.cpp) |
| Elisa | [`elisa/a/astar_csharp_spatial.elisa`](../../../elisa/a/astar_csharp_spatial.elisa) |
| Nim | [`nim/a/astar_csharp_spatial.nim`](../../../nim/a/astar_csharp_spatial.nim) |
| Odin | [`odin/a/astar_csharp_spatial.odin`](../../../odin/a/astar_csharp_spatial.odin) |
| Rust | [`rust/a/astar_csharp_spatial.rs`](../../../rust/a/astar_csharp_spatial.rs) |
| V | [`v/a/astar_csharp_spatial.v`](../../../v/a/astar_csharp_spatial.v) |
| Zig | [`zig/a/astar_csharp_spatial.zig`](../../../zig/a/astar_csharp_spatial.zig) |
