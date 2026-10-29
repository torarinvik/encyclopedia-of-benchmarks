# Manhattan minimum spanning tree

Compute the minimum total weight of a spanning tree on a bounded set of planar integer points. Every pair of points is connected by an implicit edge whose weight is their Manhattan distance.

## Contract

- The `i64_array_scalar` input is `[n, x0, y0, ..., x(n-1), y(n-1)]`.
- The point count is 1–32, and every coordinate is in `[-1,000,000, 1,000,000]`.
- Duplicate points are allowed and have distance zero. The complete metric graph is always connected.
- Return the minimum spanning tree's total Manhattan distance; a single point returns 0. Malformed input returns -1.
- The total fits in a signed 64-bit integer: any spanning tree weighs at most `31 * 4,000,000`.

Each language port uses Prim's algorithm directly on the complete metric graph. For every selected point, it updates the best known distance to each unselected point. This takes `O(n^2)` time and `O(n)` auxiliary space.

This benchmark is distinct from generic explicit-edge MST benchmarks such as `prim` and `kruskal`: those read an edge list with caller-supplied weights, while this workload derives an edge between every pair from their two-dimensional coordinates. The graph is implicit, so the implementations compute Manhattan distances as Prim grows the tree.

## Taxonomy and limits

The task is classified as a Manhattan MST following [Library Checker: Manhattan MST](https://judge.yosupo.jp/problem/manhattanmst). This package deliberately uses a small complete-graph Prim profile instead of a geometry-specific candidate-edge reduction. The bounded profile makes the distance rule and MST result directly comparable across the nine language ports.

The package oracle uses Kruskal on the explicitly generated complete metric graph as an independent workload reference. The published [`workload.json`](workload.json) includes singleton, tied-distance, duplicate-point, coordinate-boundary, maximum-size, and malformed-input cases.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/manhattan_mst.c](../../../c/m/manhattan_mst.c) |
| C3 | [c3/m/manhattan_mst.c3](../../../c3/m/manhattan_mst.c3) |
| C++ | [cpp/m/manhattan_mst.cpp](../../../cpp/m/manhattan_mst.cpp) |
| Elisa | [elisa/m/manhattan_mst.elisa](../../../elisa/m/manhattan_mst.elisa) |
| Nim | [nim/m/manhattan_mst.nim](../../../nim/m/manhattan_mst.nim) |
| Odin | [odin/m/manhattan_mst.odin](../../../odin/m/manhattan_mst.odin) |
| Rust | [rust/m/manhattan_mst.rs](../../../rust/m/manhattan_mst.rs) |
| V | [v/m/manhattan_mst.v](../../../v/m/manhattan_mst.v) |
| Zig | [zig/m/manhattan_mst.zig](../../../zig/m/manhattan_mst.zig) |

The workload checker validates the documented contract, oracle results, and presence of all nine exported source paths without compiling or launching benchmark programs.
