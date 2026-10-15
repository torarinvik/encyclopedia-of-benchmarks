# Convex Hull by Graham Scan

This benchmark implements Graham scan over planar points. It sorts points around the lowest, then leftmost pivot, and removes clockwise turns while walking the sorted points.

## Contract

- Input is an even-length array of signed 64-bit integers: `(x0, y0, x1, y1, ...)`.
- There are at most 1,024 input points. Each coordinate must be in `[-1,000,000,000, 1,000,000,000]`, keeping orientation products within signed 64-bit range.
- Duplicate coordinates represent one geometric point; the first input index represents that point.
- Return the number of hull points and write their original indices as signed 32-bit little-endian cells.
- The output starts at the lowest point, breaking ties by x, and proceeds counter-clockwise. Keep each distinct input point on the hull boundary, including collinear edge points, exactly once. For a fully collinear set, return all distinct points from the pivot outward.
- Empty input returns `0` with no output. Invalid input returns `-1`. Null or insufficient output storage returns `-2` without writing.
- Time complexity is `O(n log n)` and auxiliary storage is `O(n)`.

The coordinate domain is an exact integer subset of the upstream binary64 point domain. The source sorts by polar angle, then by distance, and uses a cross product to detect turns. These ports use exact integer orientation and deterministic ordering. They also collapse repeated coordinates and handle collinear points on the closing edge explicitly, avoiding the upstream scan's closest-first ordering issue there.

[`workload.json`](workload.json) covers empty and small sets, duplicate coordinates, clockwise and collinear boundaries, interior points, invalid inputs, and the 1,024-point limit.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm convex_hull_graham_scan --language rust
```

## Upstream references

- [TheAlgorithms/Rust `convex_hull.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/convex_hull.rs)
- [TheAlgorithms/JavaScript `ConvexHullGraham.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/ConvexHullGraham.js)
- [TheAlgorithms/Java `ConvexHull.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/ConvexHull.java)
- [TheAlgorithms/Python `convex_hull.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/convex_hull.py)

The Rust source is a Graham scan. The Java and Python recursive methods are Quickhull-style divide-and-conquer, while the JavaScript function labeled Graham uses x-sorted upper and lower chains. They share the convex-hull problem but use different constructions and boundary conventions.
