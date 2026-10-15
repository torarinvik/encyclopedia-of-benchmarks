# Digital Differential Analyzer Line

Generate raster points by repeatedly adding the dominant-axis increments as binary64 values. This is distinct from the Bresenham line algorithm: DDA uses floating-point increments and rounding; Bresenham uses integer error updates. The pinned DDA source also omits the start point, returning one rounded point after each step through the endpoint.

## Contract

The `i64_array_bytes_output` function receives exactly `[x1, y1, x2, y2]`, with each coordinate in -1,000,000 through 1,000,000. Let `steps = max(abs(x2 - x1), abs(y2 - y1))`; valid nondegenerate segments have 1 through 4,096 steps. Zero-length segments and larger step counts return `-1`.

For each step, start with binary64 `(x, y) = (x1, y1)`, add `(dx / steps, dy / steps)`, and append the rounded point. Rounding matches Python's ties-to-even `round`. The starting endpoint is omitted; the ending endpoint is included. Output is a sequence of point pairs, each stored as signed 32-bit little-endian `x` followed by signed 32-bit little-endian `y`. The function returns the output byte count. Invalid inputs return `-1`; insufficient output capacity returns `-2` with no output bytes.

[`workload.json`](workload.json) covers the source example, shallow and steep slopes, negative direction, horizontal and vertical lines, positive and negative half-way rounding, degenerate and out-of-bound inputs, insufficient output capacity, and the maximum step count.

## Implementations

The nine portable implementations are in [`c/d/digital_differential_analyzer_line.c`](../../../c/d/digital_differential_analyzer_line.c), [`c3/d/digital_differential_analyzer_line.c3`](../../../c3/d/digital_differential_analyzer_line.c3), [`cpp/d/digital_differential_analyzer_line.cpp`](../../../cpp/d/digital_differential_analyzer_line.cpp), [`elisa/d/digital_differential_analyzer_line.elisa`](../../../elisa/d/digital_differential_analyzer_line.elisa), [`nim/d/digital_differential_analyzer_line.nim`](../../../nim/d/digital_differential_analyzer_line.nim), [`odin/d/digital_differential_analyzer_line.odin`](../../../odin/d/digital_differential_analyzer_line.odin), [`rust/d/digital_differential_analyzer_line.rs`](../../../rust/d/digital_differential_analyzer_line.rs), [`v/d/digital_differential_analyzer_line.v`](../../../v/d/digital_differential_analyzer_line.v), and [`zig/d/digital_differential_analyzer_line.zig`](../../../zig/d/digital_differential_analyzer_line.zig).

## Upstream references

- [Python Digital Differential Analyzer line](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/digital_differential_analyzer_line.py)
- [Python classic Bresenham line](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/bresenham_line_basic.py)
- [Python generalized Bresenham line](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/bresenham_line_generalized.py)
- [Java Bresenham line](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/BresenhamLine.java)
