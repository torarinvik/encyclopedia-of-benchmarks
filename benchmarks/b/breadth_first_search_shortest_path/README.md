# Breadth-first search shortest path

Find one shortest path between two vertices in a bounded directed, unweighted graph. Outgoing-neighbor input order determines which path is selected when several shortest paths exist.

## Pinned sources

- Python [`breadth_first_search_shortest_path.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/breadth_first_search_shortest_path.py) builds a parent map by FIFO BFS and formats a path as an arrow-separated string.
- Python [`breadth_first_search_shortest_path_2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/breadth_first_search_shortest_path_2.py) returns the path as a list. Its separate hop-distance helper is outside this package.
- JavaScript [`BreadthFirstShortestPath.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Graphs/BreadthFirstShortestPath.js) queues candidate paths in FIFO order, scans each outgoing neighbor list in order, returns a one-vertex path for equal endpoints, and returns an empty list when the target cannot be reached. It uses the same valid-domain path selection as this contract.

The ports normalize the Python string labels to integer vertex IDs and both path APIs to one vector output. On valid finite graphs, the first shortest path follows the outgoing-neighbor order. The first source raises an exception for an unreachable target, while the second returns an empty list; the common contract represents that case as `[0]`.

## Contract

Input is a signed 64-bit array `[vertex_count, edge_count, start_vertex, goal_vertex, (from, to)...]`. There are 1 through 32 vertices and 0 through 256 directed edges. IDs are zero-based. Repeated edges and self-loops are allowed. The packed edge order defines each vertex's outgoing-neighbor order. Both endpoints and every edge endpoint must be in range.

BFS marks vertices when it enqueues them and records the parent of each first discovery. The resulting little-endian signed 64-bit vector is `[path_vertex_count, vertex_id_0, vertex_id_1, ...]`. The count includes both endpoints. Equal endpoints produce `[1, start_vertex]`; an unreachable target produces `[0]`. The function returns the number of output bytes written. Invalid input returns `-1`; insufficient or null output capacity returns `-2` without writing. The maximum output is 33 values (264 bytes).

This package returns a target path, unlike [`breadth_first_search`](../breadth_first_search/README.md), which returns the full reachable traversal order, and [`bfs_result_tree`](../bfs_result_tree/README.md), which returns the complete parent and distance maps.

## Workload

[`workload.json`](workload.json) covers the pinned demo graph, directed paths, adjacency-order ties, cycles, repeated edges, self-loops, unreachable targets, the maximum bounded path, and malformed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/breadth_first_search_shortest_path.c`](../../../c/b/breadth_first_search_shortest_path.c) |
| C3 | [`c3/b/breadth_first_search_shortest_path.c3`](../../../c3/b/breadth_first_search_shortest_path.c3) |
| C++ | [`cpp/b/breadth_first_search_shortest_path.cpp`](../../../cpp/b/breadth_first_search_shortest_path.cpp) |
| Elisa | [`elisa/b/breadth_first_search_shortest_path.elisa`](../../../elisa/b/breadth_first_search_shortest_path.elisa) |
| Nim | [`nim/b/breadth_first_search_shortest_path.nim`](../../../nim/b/breadth_first_search_shortest_path.nim) |
| Odin | [`odin/b/breadth_first_search_shortest_path.odin`](../../../odin/b/breadth_first_search_shortest_path.odin) |
| Rust | [`rust/b/breadth_first_search_shortest_path.rs`](../../../rust/b/breadth_first_search_shortest_path.rs) |
| V | [`v/b/breadth_first_search_shortest_path.v`](../../../v/b/breadth_first_search_shortest_path.v) |
| Zig | [`zig/b/breadth_first_search_shortest_path.zig`](../../../zig/b/breadth_first_search_shortest_path.zig) |
