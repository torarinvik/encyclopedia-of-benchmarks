# 3D point collinearity

Check whether three integer points lie on one line in three-dimensional space. The algorithm forms vectors from the first point to the other two and checks whether their cross product is the zero vector.

## Contract

- Input is nine signed 64-bit values in point order: `[ax, ay, az, bx, by, bz, cx, cy, cz]`.
- Each coordinate must be in `[-10,000, 10,000]`. A non-nine-element array or an out-of-range coordinate returns `-1`.
- Return `1` when all three components of `AB × AC` are zero, and `0` otherwise. Repeated points, including three identical points, therefore return `1`.
- Restricting coordinates to integers makes the zero comparison exact and keeps all cross-product arithmetic within signed 64-bit range.
- Runtime is `O(1)` with `O(1)` auxiliary space.

The pinned Python source uses floating-point point tuples and the same vector cross-product test. This benchmark uses an integer coordinate subset to provide deterministic exact behavior across the signed-integer ABI.

## Workload

[`workload.json`](workload.json) covers repeated points, axis-aligned and general lines, negative coordinates, noncollinear points, coordinate bounds, and invalid inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/points_are_collinear_3d.c`](../../../c/p/points_are_collinear_3d.c) |
| C3 | [`c3/p/points_are_collinear_3d.c3`](../../../c3/p/points_are_collinear_3d.c3) |
| C++ | [`cpp/p/points_are_collinear_3d.cpp`](../../../cpp/p/points_are_collinear_3d.cpp) |
| Elisa | [`elisa/p/points_are_collinear_3d.elisa`](../../../elisa/p/points_are_collinear_3d.elisa) |
| Nim | [`nim/p/points_are_collinear_3d.nim`](../../../nim/p/points_are_collinear_3d.nim) |
| Odin | [`odin/p/points_are_collinear_3d.odin`](../../../odin/p/points_are_collinear_3d.odin) |
| Rust | [`rust/p/points_are_collinear_3d.rs`](../../../rust/p/points_are_collinear_3d.rs) |
| V | [`v/p/points_are_collinear_3d.v`](../../../v/p/points_are_collinear_3d.v) |
| Zig | [`zig/p/points_are_collinear_3d.zig`](../../../zig/p/points_are_collinear_3d.zig) |

## Pinned source

- [Python `points_are_collinear_3d.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/points_are_collinear_3d.py)
- [Existing vector cross product benchmark](../../v/vector_cross_product/README.md)
