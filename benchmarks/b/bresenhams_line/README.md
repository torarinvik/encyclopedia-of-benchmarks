# Bresenham's Line

Rasterize the integer grid points between two endpoints with the inclusive tie comparisons from the pinned [TheAlgorithms/Nim implementation](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/graphics/bresenhams_line.nim). The result includes both endpoints and follows the source's update order: if the doubled error is at least `dy`, step in x; if it is at most `dx`, step in y.

## Contract

- Input is exactly `[x_start, y_start, x_end, y_end]` as signed 64-bit values.
- Each coordinate must be in `[-1,000,000, 1,000,000]`; each axis delta must be at most 4,096.
- Return the output byte count and write each point as little-endian signed 32-bit `x`, then little-endian signed 32-bit `y`.
- The segment includes both endpoints. A zero-length segment emits its one endpoint.
- Invalid input returns `-1`; null or insufficient output storage returns `-2` without writing.

The inclusive comparisons select different pixels for some exact half-step ties than the strict comparisons in [`bresenham_line`](../bresenham_line/README.md). This package keeps that source behavior as a distinct algorithm contract. Runtime is O(max(|dx|, |dy|)); auxiliary storage is O(1).

## Implementations

| Language | Implementation |
| --- | --- |
| C | [`c/b/bresenhams_line.c`](../../../c/b/bresenhams_line.c) |
| C3 | [`c3/b/bresenhams_line.c3`](../../../c3/b/bresenhams_line.c3) |
| C++ | [`cpp/b/bresenhams_line.cpp`](../../../cpp/b/bresenhams_line.cpp) |
| Elisa | [`elisa/b/bresenhams_line.elisa`](../../../elisa/b/bresenhams_line.elisa) |
| Nim | [`nim/b/bresenhams_line.nim`](../../../nim/b/bresenhams_line.nim) |
| Odin | [`odin/b/bresenhams_line.odin`](../../../odin/b/bresenhams_line.odin) |
| Rust | [`rust/b/bresenhams_line.rs`](../../../rust/b/bresenhams_line.rs) |
| V | [`v/b/bresenhams_line.v`](../../../v/b/bresenhams_line.v) |
| Zig | [`zig/b/bresenhams_line.zig`](../../../zig/b/bresenhams_line.zig) |

The shared workload is in [`workload.json`](workload.json). Build an implementation and its ABI checker with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm bresenhams_line --language <language> --with-checker`.
