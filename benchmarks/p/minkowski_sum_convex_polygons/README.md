# Minkowski sum of convex polygons

This benchmark constructs the convex polygon whose points are all sums `p + q`, with `p` in the first input polygon and `q` in the second. It uses the linear edge-direction merge for two strictly convex polygons.

## Contract

The exported function is `minkowski_sum_convex_polygons` with the `i64_array_bytes_output` ABI. Its input is `[n,m,x0,y0,...,x(n-1),y(n-1),u0,v0,...,u(m-1),v(m-1)]`. Each polygon has 3 through 32 vertices, integer coordinates in `[-1,000,000, 1,000,000]`, and is given in strictly convex counterclockwise order. Its first vertex may be anywhere in the cycle; repeated closing vertices and collinear consecutive vertices are invalid. The maximum valid input has 130 words; one additional word is accepted by the parser only so trailing input can be rejected.

The output is `[vertex_count,x0,y0,...]`, with signed little-endian i64 words. Vertices are counterclockwise and start at the minimum y-coordinate, breaking ties by minimum x-coordinate. The polygon is closed implicitly. Each output coordinate is in `[-2,000,000, 2,000,000]`; at most 64 vertices and 1,032 output bytes are required. The function returns bytes written. Malformed input returns `-1`; null output or insufficient capacity returns `-2` without writing. Input validation precedes output checks. The fixed workspace budget is 4,096 bytes for the input point arrays, summed vertices, and temporary rotations.

The implementation rotates each polygon to its lowest vertex, where its cyclic edge vectors are ordered by polar angle. It merges these sequences using exact half-plane and cross-product comparisons and advances both sides when their edge directions match. Validation and merging take `O(n+m)` time and `O(n+m)` bounded workspace. The primary oracle uses this same merge; the independent verifier forms every pairwise vertex sum and computes their monotone-chain hull in `O(nm log(nm))` time.

The workload covers two triangles, a square-plus-triangle sum with a shared edge direction, rotated input starts, invalid orientation/convexity, trailing data, null input/output, and output capacity. The `i64_array_bytes_output` verifier also generates maximum-size polygons, cycle rotations, translations, and capacity/error-precedence probes. See [`workload.json`](workload.json), the [primary oracle](../../minkowski_sum_convex_polygons_oracle.py), the [independent verifier](../../minkowski_sum_convex_polygons_verifier_oracle.py), and the static [package inventory checker](../../check_minkowski_sum_convex_polygons_package.py).

The algorithm was identified through the [CP-Algorithms Minkowski sum of convex polygons article](https://cp-algorithms.com/geometry/minkowski.html). The ten ports are clean-room implementations of the high-level edge-merge algorithm; no upstream code, prose, examples, or tests are copied. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/minkowski_sum_convex_polygons.c`](../../../c/p/minkowski_sum_convex_polygons.c) |
| C3 | [`c3/p/minkowski_sum_convex_polygons.c3`](../../../c3/p/minkowski_sum_convex_polygons.c3) |
| C++ | [`cpp/p/minkowski_sum_convex_polygons.cpp`](../../../cpp/p/minkowski_sum_convex_polygons.cpp) |
| Elisa | [`elisa/p/minkowski_sum_convex_polygons.elisa`](../../../elisa/p/minkowski_sum_convex_polygons.elisa) |
| Mojo | [`mojo/p/minkowski_sum_convex_polygons.mojo`](../../../mojo/p/minkowski_sum_convex_polygons.mojo) |
| Nim | [`nim/p/minkowski_sum_convex_polygons.nim`](../../../nim/p/minkowski_sum_convex_polygons.nim) |
| Odin | [`odin/p/minkowski_sum_convex_polygons.odin`](../../../odin/p/minkowski_sum_convex_polygons.odin) |
| Rust | [`rust/p/minkowski_sum_convex_polygons.rs`](../../../rust/p/minkowski_sum_convex_polygons.rs) |
| V | [`v/p/minkowski_sum_convex_polygons.v`](../../../v/p/minkowski_sum_convex_polygons.v) |
| Zig | [`zig/p/minkowski_sum_convex_polygons.zig`](../../../zig/p/minkowski_sum_convex_polygons.zig) |
