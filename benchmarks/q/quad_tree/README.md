# Point QuadTree

This benchmark captures the pinned Java point quadtree's insertion and inclusive range-query behavior. It excludes its GUI demo and restricts coordinates to an exact integer grid so the ports share deterministic subdivision boundaries.

## Contract

Input is a signed-i64 array:

```text
[root_center_x, root_center_y, root_half_width, node_capacity, point_count,
 point_0_x, point_0_y, ..., query_center_x, query_center_y, query_half_width]
```

All coordinates are integer units converted exactly to Java `double`. Root centers are in `[-2048, 2048]`, root half-width is `1..1024`, and node capacity is `1..8`. There are `0..64` input points, each coordinate is in `[-8192, 8192]`, and point coordinates must be pairwise distinct. Query centers are in `[-8192, 8192]` and query half-width is `0..8192`. The exact input length is `8 + 2 * point_count`, at most 136 words; 137 words are parseable for a trailing-data check.

Each insert is attempted in input order. Points outside the root boundary are rejected. A node keeps its existing points when it subdivides. New points route to the first child that contains them, in north-west, north-east, south-west, south-east order. Child boundaries share their midlines and containment is inclusive, so a point on a split line goes to the first matching child. The positive root width, integer point grid, and distinct-point restriction bound subdivision to at most 12 levels.

The final query uses an inclusive axis-aligned square. Non-intersecting nodes are pruned; each visited node contributes its matching local points in insertion order, then its children are queried north-west, north-east, south-west, south-east. Output order is observable and is not sorted.

Output is little-endian signed-i64 words `[point_count, insert_flag_0, ..., insert_flag_(n-1), result_count, x_0, y_0, ...]`. Flags are 0 or 1, and returned points preserve the Java traversal order. The maximum is 194 words or 1552 bytes. Success returns bytes written. Invalid input returns `-1` before output checks; null or short output returns `-2`, including when the query result is empty. Errors write no bytes.

## Pinned source

- Java [`QuadTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/QuadTree.java), class `QuadTree`, commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/quad_tree_oracle.py`](../../quad_tree_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/q/quad_tree.c`](../../../c/q/quad_tree.c) |
| C3 | [`c3/q/quad_tree.c3`](../../../c3/q/quad_tree.c3) |
| C++ | [`cpp/q/quad_tree.cpp`](../../../cpp/q/quad_tree.cpp) |
| Elisa | [`elisa/q/quad_tree.elisa`](../../../elisa/q/quad_tree.elisa) |
| Nim | [`nim/q/quad_tree.nim`](../../../nim/q/quad_tree.nim) |
| Odin | [`odin/q/quad_tree.odin`](../../../odin/q/quad_tree.odin) |
| Rust | [`rust/q/quad_tree.rs`](../../../rust/q/quad_tree.rs) |
| V | [`v/q/quad_tree.v`](../../../v/q/quad_tree.v) |
| Zig | [`zig/q/quad_tree.zig`](../../../zig/q/quad_tree.zig) |
