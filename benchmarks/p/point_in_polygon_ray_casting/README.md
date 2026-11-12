# Point in polygon by ray casting

Classify one integer query point against an ordered polygon using the even–odd horizontal-ray rule. Each crossing toggles the inside state; an odd number of crossings is inside. The edge from the final vertex back to the first is included implicitly.

## Contract

The `i64_array_scalar` input is `[n, qx, qy, x0, y0, ..., x(n-1), y(n-1)]`. The polygon has 3 through 64 ordered vertices. Every query and vertex coordinate is an integer in `[-1,000,000, 1,000,000]`. The polygon may be concave or self-intersecting; self-intersections follow even–odd fill semantics. Repeated vertices and zero-length edges are permitted. A repeated final copy of the first vertex is unnecessary but valid.

Return `1` for an inside point or a point on any polygon edge, `0` for an outside point, and `-1` for a null pointer, malformed length/count, or out-of-range coordinate. This package makes the task's unspecified boundary case inclusive. Exact integer cross-products avoid division and floating-point tie behavior. The coordinate cap bounds every cross product well within signed 64-bit range.

The ray-crossing primary oracle is [`../../point_in_polygon_ray_casting_oracle.py`](../../point_in_polygon_ray_casting_oracle.py). The independent oracle computes signed winding crossings and uses their parity in [`../../point_in_polygon_ray_casting_verifier_oracle.py`](../../point_in_polygon_ray_casting_verifier_oracle.py). [`workload.json`](workload.json) includes convex, concave, repeated-vertex, boundary, self-intersecting, and malformed cases. The static inventory checker is [`../../check_point_in_polygon_ray_casting_package.py`](../../check_point_in_polygon_ray_casting_package.py). The ten ports are registered in the `i64_array_scalar` suite, including generated maximum-size, malformed-input, and null-input records.

## Source and rights

The algorithm name and even–odd horizontal-ray definition come from the [Rosetta Code Ray-casting algorithm task](https://rosettagit.org/tasks/ray-casting-algorithm/). The RosettaGit page is licensed under GFDL 1.3-or-later. The ten ports are clean-room implementations of the algorithm description; no task prose, code, fixtures, or examples are copied. This bounded integer profile defines edge inclusion explicitly because the task leaves boundary points unspecified. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/point_in_polygon_ray_casting.c`](../../../c/p/point_in_polygon_ray_casting.c) |
| C3 | [`c3/p/point_in_polygon_ray_casting.c3`](../../../c3/p/point_in_polygon_ray_casting.c3) |
| C++ | [`cpp/p/point_in_polygon_ray_casting.cpp`](../../../cpp/p/point_in_polygon_ray_casting.cpp) |
| Elisa | [`elisa/p/point_in_polygon_ray_casting.elisa`](../../../elisa/p/point_in_polygon_ray_casting.elisa) |
| Mojo | [`mojo/p/point_in_polygon_ray_casting.mojo`](../../../mojo/p/point_in_polygon_ray_casting.mojo) |
| Nim | [`nim/p/point_in_polygon_ray_casting.nim`](../../../nim/p/point_in_polygon_ray_casting.nim) |
| Odin | [`odin/p/point_in_polygon_ray_casting.odin`](../../../odin/p/point_in_polygon_ray_casting.odin) |
| Rust | [`rust/p/point_in_polygon_ray_casting.rs`](../../../rust/p/point_in_polygon_ray_casting.rs) |
| V | [`v/p/point_in_polygon_ray_casting.v`](../../../v/p/point_in_polygon_ray_casting.v) |
| Zig | [`zig/p/point_in_polygon_ray_casting.zig`](../../../zig/p/point_in_polygon_ray_casting.zig) |
