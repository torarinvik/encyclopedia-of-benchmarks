# Convex hull by two x-sorted chains

This package follows TheAlgorithms/JavaScript's
[`ConvexHullGraham.convexHull`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/ConvexHullGraham.js).
Although the source calls it Graham scan, it sorts points by x, splits them
around the line joining the two endpoints, and builds upper and lower chains.
It does not use the polar-angle scan in
[`convex_hull_graham_scan`](../convex_hull_graham_scan/README.md).

## Contract

- Input is an even-length signed 64-bit array `(x0, y0, x1, y1, ...)` with 3
  to 64 points. Coordinates are integers in `[-2,000, 2,000]`.
- Every point has a distinct x coordinate. After sorting by x, no interior
  point lies on the line between the leftmost and rightmost points. These
  preconditions avoid vertical slope divisions and duplicated baseline points
  in the source. The bounded integer slopes preserve its orientation decisions.
- The source's orientation labels clockwise as `1` and anticlockwise as `-1`.
  It retains collinear points along the two chains. Output order is the upper
  chain's interior points followed by the lower chain in reverse, as in the
  JavaScript source.
- Return the hull count and write original input indexes as signed 32-bit
  little-endian cells. Invalid input returns `-1`; null or insufficient output
  storage returns `-2` without writing. The maximum workspace is 256 bytes.

[`workload.json`](workload.json) covers both sides of the endpoint line,
collinear chain points, sorting, interior points, invalid preconditions, and
the 64-point boundary.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm convex_hull_graham --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/convex_hull_graham/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm convex_hull_graham
```

| Language | Source |
| --- | --- |
| C | [`c/c/convex_hull_graham.c`](../../../c/c/convex_hull_graham.c) |
| C3 | [`c3/c/convex_hull_graham.c3`](../../../c3/c/convex_hull_graham.c3) |
| C++ | [`cpp/c/convex_hull_graham.cpp`](../../../cpp/c/convex_hull_graham.cpp) |
| Elisa | [`elisa/c/convex_hull_graham.elisa`](../../../elisa/c/convex_hull_graham.elisa) |
| Nim | [`nim/c/convex_hull_graham.nim`](../../../nim/c/convex_hull_graham.nim) |
| Odin | [`odin/c/convex_hull_graham.odin`](../../../odin/c/convex_hull_graham.odin) |
| Rust | [`rust/c/convex_hull_graham.rs`](../../../rust/c/convex_hull_graham.rs) |
| V | [`v/c/convex_hull_graham.v`](../../../v/c/convex_hull_graham.v) |
| Zig | [`zig/c/convex_hull_graham.zig`](../../../zig/c/convex_hull_graham.zig) |
