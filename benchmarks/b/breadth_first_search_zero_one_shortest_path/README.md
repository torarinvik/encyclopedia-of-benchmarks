# Breadth-first search zero-one shortest path

Compute the minimum total edge weight between two vertices in a bounded directed graph whose edge weights are zero or one.

## Pinned source

The pinned Python [`breadth_first_search_zero_one_shortest_path.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/breadth_first_search_zero_one_shortest_path.py) uses a deque-based 0–1 BFS. It adds zero-weight improvements to the front and one-weight improvements to the back, and returns the scalar distance. The source raises `ValueError` when the target cannot be reached; this package maps that case to `-1` for the shared benchmark contract.

## Contract

Input is a signed 64-bit array `[vertex_count, edge_count, start, finish, (from, to, weight)...]`. There are 1 through 64 vertices and 0 through 256 directed edges. Vertex IDs are zero-based. Parallel edges and self-loops are allowed. Edges retain input order within each source vertex. Every endpoint must be in range and each weight must be exactly zero or one. The exact input length is `4 + 3 * edge_count`, with a maximum of 772 values.

The result is the minimum sum of edge weights from `start` to `finish`. A vertex is reachable from itself with cost zero. An unreachable finish returns `-1`; malformed or out-of-range input returns `-2`.

This is the single-target, zero-or-one-weight counterpart to [`dijkstra_positive_connected`](../../d/dijkstra_positive_connected/README.md), which handles positive weights and returns distances to every vertex.

## Workload

[`workload.json`](workload.json) covers zero and one cost routes, directed reachability, parallel edges, zero-weight cycles, self-loops, the maximum vertex and edge counts, and malformed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/breadth_first_search_zero_one_shortest_path.c`](../../../c/b/breadth_first_search_zero_one_shortest_path.c) |
| C3 | [`c3/b/breadth_first_search_zero_one_shortest_path.c3`](../../../c3/b/breadth_first_search_zero_one_shortest_path.c3) |
| C++ | [`cpp/b/breadth_first_search_zero_one_shortest_path.cpp`](../../../cpp/b/breadth_first_search_zero_one_shortest_path.cpp) |
| Elisa | [`elisa/b/breadth_first_search_zero_one_shortest_path.elisa`](../../../elisa/b/breadth_first_search_zero_one_shortest_path.elisa) |
| Nim | [`nim/b/breadth_first_search_zero_one_shortest_path.nim`](../../../nim/b/breadth_first_search_zero_one_shortest_path.nim) |
| Odin | [`odin/b/breadth_first_search_zero_one_shortest_path.odin`](../../../odin/b/breadth_first_search_zero_one_shortest_path.odin) |
| Rust | [`rust/b/breadth_first_search_zero_one_shortest_path.rs`](../../../rust/b/breadth_first_search_zero_one_shortest_path.rs) |
| V | [`v/b/breadth_first_search_zero_one_shortest_path.v`](../../../v/b/breadth_first_search_zero_one_shortest_path.v) |
| Zig | [`zig/b/breadth_first_search_zero_one_shortest_path.zig`](../../../zig/b/breadth_first_search_zero_one_shortest_path.zig) |
