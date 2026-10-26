# Unit-disk graph WSPD

This is an exact bounded WSPD profile for the shortest-path metric of a unit-disk graph, matching the metric and pair-decomposition object described in Encyclopedia of Algorithms chapter DOI 480. It is deliberately restricted to integer-lattice points: with unit radius, every edge between distinct integer points has length exactly one, so graph distances and separation tests are exact integers across all nine ports.

## Contract

- ABI: `i64_array_bytes_output`; input is `[point_count, separation_factor, x0, y0, ...]`.
- `point_count` is 1..8; `separation_factor` is 1..8; coordinates are integers in `[-8,8]`; coordinates must be unique. Inputs whose induced unit-disk graph is disconnected are invalid.
- An edge exists when squared Euclidean distance is at most 1. Because the coordinates are integral and unique, every such edge has unit weight. Distances are shortest-path distances in that graph.
- A pair of nonempty disjoint vertex sets A,B is accepted when `dist(A,B) >= c * max(diam(A), diam(B))`, using the chapter's graph-metric separation definition and an inclusive comparison.
- To fix the output for small inputs, a balanced split tree recursively divides the ascending original point IDs in half. A node is traversed left, then right, then its cross-pair. An unseparated cross-pair splits the larger set; equal-size ties split the second set. The recursion emits each unordered point pair exactly once.
- Output is little-endian signed 64-bit words `[pair_count, left_mask_0, right_mask_0, ...]`; bit `i` denotes original point `i`. Pair order follows the traversal above. Return the number of written bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.
- At most 28 point pairs can be emitted, so output is bounded by 456 bytes.

This is a small deterministic construction of the chapter's WSPD object under its unit-disk graph metric. It does not implement Gao–Zhang's bounded-density clustering and near-linear-size construction; the integer-lattice restriction and the exact shortest-path metric make the profile portable and independently checkable.

## Provenance and implementations

The source description is Rolf Klein, “Well Separated Pair Decomposition for Unit-Disk Graph,” DOI [`10.1007/978-1-4939-2864-4_480`](https://doi.org/10.1007/978-1-4939-2864-4_480), summarizing Gao and Zhang, “Well-separated pair decomposition for the unit-disk graph metric and its applications” (STOC 2003). The clean-room ports implement the mathematical definition and bounded traversal above; they do not copy the chapter or paper's prose or code.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the [primary oracle](../../unit_disk_graph_wspd_oracle.py), and the [independent verifier oracle](../../unit_disk_graph_wspd_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/u/unit_disk_graph_wspd.c`](../../../c/u/unit_disk_graph_wspd.c) |
| C3 | [`c3/u/unit_disk_graph_wspd.c3`](../../../c3/u/unit_disk_graph_wspd.c3) |
| C++ | [`cpp/u/unit_disk_graph_wspd.cpp`](../../../cpp/u/unit_disk_graph_wspd.cpp) |
| Elisa | [`elisa/u/unit_disk_graph_wspd.elisa`](../../../elisa/u/unit_disk_graph_wspd.elisa) |
| Nim | [`nim/u/unit_disk_graph_wspd.nim`](../../../nim/u/unit_disk_graph_wspd.nim) |
| Odin | [`odin/u/unit_disk_graph_wspd.odin`](../../../odin/u/unit_disk_graph_wspd.odin) |
| Rust | [`rust/u/unit_disk_graph_wspd.rs`](../../../rust/u/unit_disk_graph_wspd.rs) |
| V | [`v/u/unit_disk_graph_wspd.v`](../../../v/u/unit_disk_graph_wspd.v) |
| Zig | [`zig/u/unit_disk_graph_wspd.zig`](../../../zig/u/unit_disk_graph_wspd.zig) |
