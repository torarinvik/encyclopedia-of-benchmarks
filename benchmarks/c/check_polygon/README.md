# Check Polygon

This benchmark checks whether a set of side lengths can form a nondegenerate polygon in the Euclidean plane.

## Contract

- Input is an array of 3 to 256 positive signed 64-bit side lengths. Each length is at most `1,000,000,000`.
- Return `1` when the longest side is strictly shorter than the sum of all other sides; otherwise return `0`.
- Invalid input returns `-1`. The result has no output bytes.
- Time complexity is `O(n)` and auxiliary storage is `O(1)`.

The pinned Python source sorts the side lengths and applies the strict polygon inequality. A single pass that tracks the largest side and total sum computes the same condition. Equality is degenerate and therefore returns `0`.

This checks whether a polygon can exist from its side lengths alone. [`line_segment_intersection`](../../l/line_segment_intersection/README.md) checks intersections between explicit segments, while [`ear_clipping_polygon_triangulation`](../../e/ear_clipping_polygon_triangulation/README.md) triangulates an already specified polygon by its vertices.

[`workload.json`](workload.json) includes valid triangles and polygons, equality and impossible cases, large lengths, and invalid input.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm check_polygon --language rust
```

## Upstream reference

- [TheAlgorithms/Python `check_polygon.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/check_polygon.py)
