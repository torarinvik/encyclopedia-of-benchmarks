# Monotone chain convex hull

This benchmark follows the pinned Python Andrew monotone-chain routine on bounded integer points. It sorts the points lexicographically, removes duplicates, then builds the lower and upper chains while discarding any last turn whose cross product is nonpositive.

The pinned [JavaScript `ConvexHullGraham.convexHull`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/ConvexHullGraham.js)
also belongs to this family. Its original-index output can be compared with
this benchmark's coordinate output on distinct-x inputs with no collinear
triples after normalizing cyclic order and direction. The JavaScript version
retains intermediate boundary-collinear points; those inputs are excluded from
this source mapping because this benchmark discards them.
The verifier source includes the migrated mixed-side fixture and its reversed
input ordering to check that the coordinate hull is independent of input order;
these checks have not been run.

## Contract

- The packed `i64_array_bytes_output` input is `[point_count, x_0, y_0, ..., x_(n-1), y_(n-1)]`; the frame length is exactly `1 + 2 * point_count`.
- The point count is in `[0, 64]`; each coordinate is an integer in `[-1,000,000, 1,000,000]`. This bounded integer subset keeps orientation cross products exact in signed 64-bit arithmetic.
- Output is the unique convex-hull vertices as `(x, y)` signed-i32 pairs in little-endian byte order. Nondegenerate hulls are counter-clockwise from the lexicographically smallest vertex. The source's `cross <= 0` rule drops intermediate collinear boundary points; all-collinear input returns its two endpoints. Zero points returns an empty byte sequence, and one unique point returns that point.
- A null input, malformed frame, point-count violation, or out-of-range coordinate returns `-1`. A null output pointer or insufficient capacity returns `-2` without writing, including a null output for the empty hull.

Source: [Python `monotone_chain.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/monotone_chain.py).

Build and record with the `i64_array_bytes_output` ABI family and `benchmarks/run_i64_array_bytes_output.py`.
