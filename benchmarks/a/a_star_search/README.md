# A* search on a unit-cost graph

This benchmark captures the shared A* pathfinding core from the pinned Python, C++, and R candidates. It uses a directed graph with unit-cost edges and a consistent nonnegative heuristic. The shared result is a shortest path, represented as vertex IDs. The source APIs differ: Python searches a four-neighbor obstacle grid and also returns an action map; C++ provides a generic state-search class and demonstrates it with sliding puzzles; R accepts weighted adjacency lists and returns score and predecessor vectors as well as a path. The benchmark normalizes those APIs to the same graph path contract. C++'s default depth cutoff is 30, so reachable benchmark paths are bounded to at most 30 edges.

## Input and output

The `i64_array_bytes_output` function receives one signed 64-bit array encoded as:

`[vertex_count, edge_count, source, target, h(0), ..., h(V-1), from(0), to(0), ...]`

Edges are directed and each has cost 1. Parallel edges and self-edges are allowed. The graph has 1 through 256 vertices and at most 4,096 edges. Source and target are zero-based vertex IDs. Each heuristic is an integer in `[0, 1,000,000,000]`; the target heuristic must be zero, and every edge `(u, v)` must satisfy `h(u) <= 1 + h(v)`. Reachable targets in valid cases have a shortest path of at most 30 edges.

The returned byte sequence contains the path's vertex IDs in source-to-target order, one byte per ID. The function return value is the path length in vertices. An unreachable target returns zero with no bytes; `source == target` returns a one-vertex path. Malformed inputs return `-1`, and a valid call whose output buffer cannot hold the path returns `-2` without writing output.

To make the path result reproducible, the shared contract selects the open vertex with the lowest `(g + h, g, vertex_id)` tuple, scans outgoing edges in input order, and changes a predecessor only when it finds a strictly shorter route. The consistent-heuristic restriction lets the implementations close popped vertices without reopening them while preserving shortest paths.

[`workload.json`](workload.json) includes direct, unreachable, equal-cost, grid-derived, high-ID, and depth-limit cases. The independent verifier adds seeded random graphs and malformed-input cases, then checks all nine target-language ports and validates recorded workload outputs.

## Implementations

The portable implementations are in [`c/a/a_star_search.c`](../../../c/a/a_star_search.c), [`c3/a/a_star_search.c3`](../../../c3/a/a_star_search.c3), [`cpp/a/a_star_search.cpp`](../../../cpp/a/a_star_search.cpp), [`elisa/a/a_star_search.elisa`](../../../elisa/a/a_star_search.elisa), [`nim/a/a_star_search.nim`](../../../nim/a/a_star_search.nim), [`odin/a/a_star_search.odin`](../../../odin/a/a_star_search.odin), [`rust/a/a_star_search.rs`](../../../rust/a/a_star_search.rs), [`v/a/a_star_search.v`](../../../v/a/a_star_search.v), and [`zig/a/a_star_search.zig`](../../../zig/a/a_star_search.zig).

Run `python3 benchmarks/verify_a_star_search.py --elisa-compiler PATH/TO/elisac` to verify the ports.

## Reviewed source variants

- [Python grid A*](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/a_star.py)
- [C++ generic state-space A*](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/machine_learning/a_star_search.cpp)
- [R weighted-graph A*](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/graph_algorithms/a_star_search.r)
