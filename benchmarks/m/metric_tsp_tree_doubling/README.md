# Metric TSP tree doubling

This profile implements the tree-doubling 2-approximation for metric TSP. It
constructs a deterministic minimum spanning tree, performs a depth-first
preorder from vertex 0, shortcuts repeat visits, and closes the tour at 0.
Kruskal edges are ordered by `(weight,u,v)`; preorder visits tree neighbors in
ascending ID order.

Input is `[n, row-major n-by-n distance matrix]`, with `1 <= n <= 8`, integral
distances in `[0,10000]`, zero diagonal, symmetry, and the triangle inequality.
Output is `[tour_cost, 0, preorder_after_root..., 0]` as little-endian signed
i64 values. Invalid input returns `-1`; null output or insufficient capacity
returns `-2` without writing.

The source is “Metric TSP,” DOI
[`10.1007/978-1-4939-2864-4_230`](https://doi.org/10.1007/978-1-4939-2864-4_230).
The tree-doubling profile is clean-room and does not copy book prose or source
code. It is distinct from nearest-neighbor and exact subset-DP TSP profiles.

| Language | Port |
|---|---|
| C | `c/m/metric_tsp_tree_doubling.c` |
| C3 | `c3/m/metric_tsp_tree_doubling.c3` |
| C++ | `cpp/m/metric_tsp_tree_doubling.cpp` |
| Elisa | `elisa/m/metric_tsp_tree_doubling.elisa` |
| Nim | `nim/m/metric_tsp_tree_doubling.nim` |
| Odin | `odin/m/metric_tsp_tree_doubling.odin` |
| Rust | `rust/m/metric_tsp_tree_doubling.rs` |
| V | `v/m/metric_tsp_tree_doubling.v` |
| Zig | `zig/m/metric_tsp_tree_doubling.zig` |
