# Breadth-First Search Shortest-Path Distance

This package returns the minimum number of directed edges from one vertex to another. Input is `[vertex_count, edge_count, source, target, (from, to)...]`; vertex IDs are zero-based and correspond to the single-character labels `A` through `Z`. The character mapping preserves the pinned helper's single-character start-label limitation while allowing the graph to be represented as bounded numeric arrays.

The graph must contain 1 through 26 vertices and at most 256 input edges. Every edge endpoint and both query vertices must be in range, and the input length must equal `4 + 2 * edge_count`. Repeated edges and self-loops are allowed. The graph is directed. A valid query with identical source and target returns `0`; an unreachable target or malformed input returns `-1`.

| Language | Port |
|---|---|
| C | [`c/b/breadth_first_search_shortest_path_distance.c`](../../../c/b/breadth_first_search_shortest_path_distance.c) |
| C3 | [`c3/b/breadth_first_search_shortest_path_distance.c3`](../../../c3/b/breadth_first_search_shortest_path_distance.c3) |
| C++ | [`cpp/b/breadth_first_search_shortest_path_distance.cpp`](../../../cpp/b/breadth_first_search_shortest_path_distance.cpp) |
| Elisa | [`elisa/b/breadth_first_search_shortest_path_distance.elisa`](../../../elisa/b/breadth_first_search_shortest_path_distance.elisa) |
| Nim | [`nim/b/breadth_first_search_shortest_path_distance.nim`](../../../nim/b/breadth_first_search_shortest_path_distance.nim) |
| Odin | [`odin/b/breadth_first_search_shortest_path_distance.odin`](../../../odin/b/breadth_first_search_shortest_path_distance.odin) |
| Rust | [`rust/b/breadth_first_search_shortest_path_distance.rs`](../../../rust/b/breadth_first_search_shortest_path_distance.rs) |
| V | [`v/b/breadth_first_search_shortest_path_distance.v`](../../../v/b/breadth_first_search_shortest_path_distance.v) |
| Zig | [`zig/b/breadth_first_search_shortest_path_distance.zig`](../../../zig/b/breadth_first_search_shortest_path_distance.zig) |

Pinned source: [TheAlgorithms/Python `breadth_first_search_shortest_path_2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/breadth_first_search_shortest_path_2.py). The source computes distance in edge counts and returns `-1` when no route exists. Its `set(start)` initialization assumes a one-character start label, which is why this package uses `A` through `Z`. The workload covers directed reachability, shortest-route choice, cycles, duplicate edges, self-loops, the 26-vertex boundary, and malformed inputs.
