# Convex Hull by Quickhull

This benchmark constructs the planar convex hull with Quickhull. Starting from the lexicographically smallest and largest points, it repeatedly selects the point farthest from a directed segment and recurses on the two new segments.

## Contract

- Input is an even-length array of signed 64-bit integers: `(x0, y0, x1, y1, ...)`.
- There are at most 1,024 input points. Each coordinate must be in `[-1,000,000,000, 1,000,000,000]`, keeping orientation products within signed 64-bit range.
- Duplicate coordinates represent one geometric point; the first input index represents that point.
- Return the number of extreme hull vertices and write their original indices as signed 32-bit little-endian cells.
- Return indices in increasing `(x,y)` coordinate order. Omit collinear points between the endpoints of a hull edge.
- Empty input returns `0` with no output. Invalid input returns `-1`. Null or insufficient output storage returns `-2` without writing.
- Quickhull is `O(n log n)` on typical inputs and `O(n^2)` in the worst case; auxiliary storage is `O(n)`.

The bounded integer coordinate domain is an exact subset of the upstream binary64 point domain. Cross products replace floating-point signed-distance calculations without changing the farthest-point choice. The common ordering and duplicate rules make the Python set result and Java counter-clockwise result directly comparable.

[`workload.json`](workload.json) covers empty and small inputs, interior points, duplicates, collinear edges and sets, negative coordinates, invalid inputs, and the 1,024-point limit.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm convex_hull_quickhull --language rust
```

## Upstream references

- [TheAlgorithms/Java `ConvexHull.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/ConvexHull.java)
- [TheAlgorithms/Python `convex_hull.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/divide_and_conquer/convex_hull.py)

The Java class also contains a brute-force variant; this benchmark follows its recursive farthest-point method and the Python `convex_hull_recursive` function. The Python function returns a lexicographically sorted point set, while Java sorts counter-clockwise. This contract standardizes output ordering and excludes intermediate collinear points.
