# Bresenham Line

Rasterize the integer grid points along a segment using Bresenham's integer error update. Both endpoints appear in the output.

## Contract

- Input is exactly `[x0, y0, x1, y1]` as signed 64-bit integers. Coordinates are in `[-1,000,000, 1,000,000]`, and the larger absolute coordinate delta is at most 4,096.
- Return the number of output bytes. Emit each raster point in traversal order, including the starting and ending endpoints, as signed 32-bit little-endian `x` followed by signed 32-bit little-endian `y`.
- A zero-length segment is valid and emits its single endpoint.
- The source's strict comparisons (`e2 > -dy` and `e2 < dx`) define tie pixels. Reversing a segment can therefore produce a different raster path for exact half-step ties.
- Invalid input returns `-1`. Null or insufficient output storage returns `-2` without writing.
- Time complexity is `O(max(|dx|, |dy|))`; auxiliary storage is `O(1)`.

The pinned Java source uses integer error updates, while [`digital_differential_analyzer_line`](../../d/digital_differential_analyzer_line/README.md) accumulates floating-point increments and rounds each step. That DDA benchmark omits its starting endpoint and rejects zero-length segments; this Bresenham contract includes both endpoints and emits one point for a degenerate segment.

[`workload.json`](workload.json) covers horizontal, vertical, diagonal, shallow and steep slopes, negative directions, tie cases, zero-length input, and invalid bounds.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm bresenham_line --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm bresenham_line
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm bresenham_line --languages rust
```

## Upstream reference

- [TheAlgorithms/Java `BresenhamLine.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/BresenhamLine.java)
