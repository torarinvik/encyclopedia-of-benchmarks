# Midpoint Circle

This benchmark plots integer points on a circle with the midpoint circle algorithm.

## Contract

- Input is three signed 64-bit integers: `(center_x, center_y, radius)`. The center coordinates must each be in `[-10,000, 10,000]`; radius must be in `[0, 1,000]`.
- Radius zero returns the center once. For positive radii, the routine begins at `(radius, 0)`, appends all eight symmetric points in the order shown in the upstream Java implementation, then advances while `x > y` using its midpoint decision parameter.
- Points are emitted as ordered `(x,y)` pairs encoded as little-endian signed 32-bit integers. Axis and diagonal duplicates are preserved exactly as generated; ports do not deduplicate or reorder points.
- Return the number of emitted points. Invalid input returns `-1`; null or insufficient output storage returns `-2` without writing. Each point takes eight bytes.
- Time is `O(radius)` and auxiliary storage is `O(1)` beyond the caller-provided output buffer. Ports count the output first so a short buffer never receives a partial result.

The Java source plots the circumference and retains duplicate points from symmetry at axes and diagonals. Existing local circle-related candidates implement circle area/perimeter, circle sort, or a circular linked list, so none implement this rasterization algorithm.

[`workload.json`](workload.json) covers radius zero, axis duplicates, diagonal duplicates, translated centers, and invalid bounds.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm midpoint_circle --language rust
```

## Upstream references

- [TheAlgorithms/Java `MidpointCircle.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/MidpointCircle.java)
- [TheAlgorithms/JavaScript `Circle.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Geometry/Circle.js)
- [TheAlgorithms/Python `circle_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/circle_sort.py)
