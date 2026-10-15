# Midpoint Ellipse

This benchmark rasterizes an integer ellipse with the two-region midpoint ellipse algorithm.

## Contract

- Input is four signed 64-bit integers `(center_x, center_y, a, b)`. Center coordinates are in `[-10,000, 10,000]`; horizontal and vertical semi-axes are each in `[0, 100]`.
- When both axes are zero, emit the center once. If only `a` is zero, emit the vertical line from `center_y-b` through `center_y+b` in ascending order. If only `b` is zero, emit the horizontal line from `center_x-a` through `center_x+a`.
- For positive axes, use the Java source's two decision regions, stopping and update rules. At each step emit four symmetric points in this order: `(cx+x,cy+y)`, `(cx-x,cy+y)`, `(cx+x,cy-y)`, `(cx-x,cy-y)`. Preserve duplicates when `x` or `y` is zero.
- Return the number of points and write ordered coordinate pairs as little-endian signed 32-bit integers. Invalid input returns `-1`; null or insufficient output storage returns `-2` without writing. Each point takes eight bytes.
- Time is `O(a+b)` and auxiliary storage is `O(1)` beyond the caller-provided output buffer. Ports count points before writing so a short buffer never receives a partial result.

The Java midpoint ellipse source implements two-region rasterization. The existing ellipse-related local benchmark computes ellipse area, which is a different operation; the midpoint circle benchmark likewise plots a different curve using a single-region recurrence and eight-way symmetry.

[`workload.json`](workload.json) covers both degenerate axes, each decision region, wide and tall ellipses, symmetry duplicates, translated centers, and invalid bounds.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm midpoint_ellipse --language rust
```

## Upstream reference

- [TheAlgorithms/Java `MidpointEllipse.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/MidpointEllipse.java)
