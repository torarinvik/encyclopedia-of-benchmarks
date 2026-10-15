# DDA line rasterization (Java variant)

This package ports the pinned [TheAlgorithms/Java `DDALine.findLine`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/DDALine.java). It includes both endpoints, adds binary64 increments over the dominant axis, and rounds coordinates with Java `Math.round` behavior (ties toward positive infinity). A zero-length segment produces the supplied starting point because the source loop appends it before adding its `NaN` increment.

The `i64_array_bytes_output` ABI accepts `[x0, y0, x1, y1]`, with coordinates in -128..128 (so there are at most 256 steps). Output stores every point, including both endpoints, as signed i64 little-endian `x` then `y`. Invalid input returns `-1`; insufficient output capacity returns `-2`.

This Java variant remains separate from `digital_differential_analyzer_line`, whose Python source omits the starting point and uses ties-to-even rounding.

[`workload.json`](workload.json) covers endpoint inclusion, shallow and vertical lines, Java rounding at positive and negative half values, the degenerate case, invalid bounds, and capacity errors. The maximum output is 4,112 bytes.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/ddaline.c`](../../../c/d/ddaline.c) |
| C3 | [`c3/d/ddaline.c3`](../../../c3/d/ddaline.c3) |
| C++ | [`cpp/d/ddaline.cpp`](../../../cpp/d/ddaline.cpp) |
| Elisa | [`elisa/d/ddaline.elisa`](../../../elisa/d/ddaline.elisa) |
| Nim | [`nim/d/ddaline.nim`](../../../nim/d/ddaline.nim) |
| Odin | [`odin/d/ddaline.odin`](../../../odin/d/ddaline.odin) |
| Rust | [`rust/d/ddaline.rs`](../../../rust/d/ddaline.rs) |
| V | [`v/d/ddaline.v`](../../../v/d/ddaline.v) |
| Zig | [`zig/d/ddaline.zig`](../../../zig/d/ddaline.zig) |
