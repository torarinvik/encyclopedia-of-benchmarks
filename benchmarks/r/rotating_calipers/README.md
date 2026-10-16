# Rotating Calipers Diameter

Find the maximum Euclidean distance between any two points in a bounded planar point set using a convex hull and an antipodal rotating-calipers sweep.

## Contract

- Input is a packed signed 64-bit array: `[point_count, x0, y0, x1, y1, ...]`.
- The point count must be from 2 through 1,024, and the packed length must equal `1 + 2 * point_count`.
- Each coordinate is in `[-1,000,000,000, 1,000,000,000]`. Duplicate points are allowed.
- Return the diameter as a binary64 Euclidean distance. If all input points are identical, return `0.0`.
- Compare binary64 results with absolute and relative tolerances of `1e-12`.
- Invalid input returns `-1e300`.
- The largest possible squared distance is `8,000,000,000,000,000,000`, which fits signed 64-bit arithmetic. The maximum diameter is its binary64 square root.
- The algorithm sorts and deduplicates points, builds the extreme-vertex hull with Andrew's monotone chain, then advances antipodal pairs around the hull. Time is `O(n log n)` and auxiliary space is `O(n)`.

## Source semantics

This follows pinned [TheAlgorithms/Python `rotating_calipers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/rotating_calipers.py). The source constructs a counter-clockwise Andrew monotone-chain hull, then sweeps antipodal points and returns the maximum distance and a pair of hull points. The benchmark returns the diameter only because the existing `i64_array_float64` ABI carries an array input and one binary64 result. Coordinates are bounded integers so orientation and squared-distance comparisons are exact before the final square root.

The existing `convex_hull_graham_scan` and `convex_hull_quickhull` benchmarks return hull vertices, and `closest_pair_divide_and_conquer` returns a minimum-distance pair. This benchmark returns the maximum distance across the point set, so it measures a separate geometry operation.

## Workload and build

[`workload.json`](workload.json) covers rectangles, an irrational diameter, interior and duplicate points, collinear points, maximum coordinates, and invalid packed inputs.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm rotating_calipers --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/r/rotating_calipers/rust/build.json
python3 benchmarks/verify_rotating_calipers.py --languages rust
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/rotating_calipers.c`](../../../c/r/rotating_calipers.c) |
| C3 | [`c3/r/rotating_calipers.c3`](../../../c3/r/rotating_calipers.c3) |
| C++ | [`cpp/r/rotating_calipers.cpp`](../../../cpp/r/rotating_calipers.cpp) |
| Elisa | [`elisa/r/rotating_calipers.elisa`](../../../elisa/r/rotating_calipers.elisa) |
| Nim | [`nim/r/rotating_calipers.nim`](../../../nim/r/rotating_calipers.nim) |
| Odin | [`odin/r/rotating_calipers.odin`](../../../odin/r/rotating_calipers.odin) |
| Rust | [`rust/r/rotating_calipers.rs`](../../../rust/r/rotating_calipers.rs) |
| V | [`v/r/rotating_calipers.v`](../../../v/r/rotating_calipers.v) |
| Zig | [`zig/r/rotating_calipers.zig`](../../../zig/r/rotating_calipers.zig) |
