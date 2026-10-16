# Wu's line

This benchmark ports the pinned Java `WusLine.drawLine` implementation of Xiaolin Wu's antialiased line rasterizer. It emits two pixels for each line column (or row for steep lines), with fractional coverage values.

## Contract

The `i64_array_bytes_output` input is exactly `[x0, y0, x1, y1]`. Each endpoint coordinate must be in `[-64, 64]`; this bounded subset keeps the Java `int` differences safe and caps the pixel output. Invalid input returns `-1`.

Each output record is exactly 16 bytes: a little-endian signed 32-bit `x`, a little-endian signed 32-bit `y`, and a little-endian IEEE-754 binary64 intensity. Intensities are clamped to `[0, 1]`. Return the number of bytes written. A null output pointer or capacity below the complete output size returns `-2` without writing.

The result follows the source's emission order: append the first endpoint pair, append the second endpoint pair, then append the interior pairs in increasing major-axis order. For steep lines, coordinates are swapped for rasterization and swapped back in each record. As in the source, endpoints are normalized to increasing major-axis coordinate, so reversing the caller's endpoints does not reverse the emitted sequence. A zero-length segment follows the source's `gradient = 1.0` branch and emits four records, including repeated coordinates and zero intensities.

The coordinate cap bounds the maximum raster span to 128 steps. At most 258 records (4,128 bytes) are emitted. The workload stores expected outputs as exact little-endian byte strings.

## Pinned source

[TheAlgorithms/Java `WusLine.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/WusLine.java) is pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

The independent byte-output oracle is [`benchmarks/wus_line_oracle.py`](../../wus_line_oracle.py), and [`workload.json`](workload.json) covers horizontal, shallow, steep, reversed, negative-coordinate, degenerate, maximum-span, malformed, and insufficient-capacity inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/wus_line.c`](../../../c/w/wus_line.c) |
| C3 | [`c3/w/wus_line.c3`](../../../c3/w/wus_line.c3) |
| C++ | [`cpp/w/wus_line.cpp`](../../../cpp/w/wus_line.cpp) |
| Elisa | [`elisa/w/wus_line.elisa`](../../../elisa/w/wus_line.elisa) |
| Nim | [`nim/w/wus_line.nim`](../../../nim/w/wus_line.nim) |
| Odin | [`odin/w/wus_line.odin`](../../../odin/w/wus_line.odin) |
| Rust | [`rust/w/wus_line.rs`](../../../rust/w/wus_line.rs) |
| V | [`v/w/wus_line.v`](../../../v/w/wus_line.v) |
| Zig | [`zig/w/wus_line.zig`](../../../zig/w/wus_line.zig) |
