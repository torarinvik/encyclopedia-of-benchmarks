# Manhattan MST candidate-edge reduction

This profile constructs an `O(n)` candidate-edge set for a Manhattan minimum spanning tree with four octant sweeps, then runs Kruskal on that sparse graph. The local [`manhattan_mst`](../manhattan_mst/README.md) profile uses complete-graph Prim; this package measures the distinct geometric reduction that avoids materializing all point pairs.

## Contract

- ABI: `i64_array_scalar`. Input is `[N,(x,y)*N]` with exact framing; `N` is 0 through 31 and both coordinates are in `[-1000,1000]`.
- Valid point sets have pairwise distinct x coordinates and pairwise distinct y coordinates. Repeated x or y values are invalid.
- The method performs four coordinate transforms. In each sweep it sorts by `x+y`, processes the active point with greatest `x<=current_x`, and removes that point while the octant inequality permits a candidate edge. A Fenwick tree over compressed x coordinates supports active predecessor selection. The final MST weight comes from Kruskal over generated edges.
- The return value is the total Manhattan MST weight. Inputs with zero or one point return 0; malformed input returns `-1`.
- Maximum valid input length is 63 words; maximum parseable length is 64. At most `4N` candidate edges are generated. The bounded workspace is 8192 bytes.

This is a method benchmark rather than a second copy of the dense Prim workload: candidate generation reduces the complete graph to linear-many edges before the spanning-tree phase. The independent oracle uses complete-graph Prim and does not use the octant reduction.

## Algorithm sources

The candidate-edge reduction follows the four-sweep Manhattan MST description in [CP-Algorithms](https://cp-algorithms.com/geometry/manhattan-distance.html#manhattan-minimum-spanning-tree) and the [KACTL Manhattan MST header](https://github.com/kth-competitive-programming/kactl/blob/main/content/geometry/ManhattanMST.h). The KACTL header identifies its source as CC0; this package is independently implemented from the method description and does not copy the header. See [`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) covers empty and singleton inputs, diagonal and general point sets, negative coordinates, equal-distance ties, duplicate-axis rejection, coordinate bounds, and malformed framing.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/manhattan_mst_candidate_edge_reduction.c`](../../../c/m/manhattan_mst_candidate_edge_reduction.c) |
| C3 | [`c3/m/manhattan_mst_candidate_edge_reduction.c3`](../../../c3/m/manhattan_mst_candidate_edge_reduction.c3) |
| C++ | [`cpp/m/manhattan_mst_candidate_edge_reduction.cpp`](../../../cpp/m/manhattan_mst_candidate_edge_reduction.cpp) |
| Elisa | [`elisa/m/manhattan_mst_candidate_edge_reduction.elisa`](../../../elisa/m/manhattan_mst_candidate_edge_reduction.elisa) |
| Mojo | [`mojo/m/manhattan_mst_candidate_edge_reduction.mojo`](../../../mojo/m/manhattan_mst_candidate_edge_reduction.mojo) |
| Nim | [`nim/m/manhattan_mst_candidate_edge_reduction.nim`](../../../nim/m/manhattan_mst_candidate_edge_reduction.nim) |
| Odin | [`odin/m/manhattan_mst_candidate_edge_reduction.odin`](../../../odin/m/manhattan_mst_candidate_edge_reduction.odin) |
| Rust | [`rust/m/manhattan_mst_candidate_edge_reduction.rs`](../../../rust/m/manhattan_mst_candidate_edge_reduction.rs) |
| V | [`v/m/manhattan_mst_candidate_edge_reduction.v`](../../../v/m/manhattan_mst_candidate_edge_reduction.v) |
| Zig | [`zig/m/manhattan_mst_candidate_edge_reduction.zig`](../../../zig/m/manhattan_mst_candidate_edge_reduction.zig) |
