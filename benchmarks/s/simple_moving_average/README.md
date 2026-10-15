# Simple moving average

This package ports the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/simple_moving_average.py). For each position it emits `None` until a complete trailing window is available, then emits the arithmetic mean of that window. Each window is summed independently, matching the source's slice-and-sum calculation.

The `i64_array_bytes_output` ABI packs `[window_size, n, data[0..n]]`. The benchmarked domain is `1 <= window_size <= 256`, `1 <= n <= 256`, with signed 32-bit data values. The result has exactly `n` entries, including when the window is larger than the data. Entries are packed as little-endian IEEE-754 binary64 bytes; unavailable `None` entries use the canonical quiet-NaN bit pattern `0x7ff8000000000000`. Invalid input returns `-1`; insufficient output capacity returns `-2`; success returns `8*n`.

The bounded integer domain keeps every window sum exact in signed 64-bit arithmetic before conversion to binary64. Runtime is `O(n * window_size)` and auxiliary space is `O(1)` beyond the output buffer.

## Workload

[`workload.json`](workload.json) includes the upstream examples, a window larger than the data, a single-value window, negative values, and malformed/out-of-range inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/simple_moving_average.c`](../../../c/s/simple_moving_average.c) |
| C3 | [`c3/s/simple_moving_average.c3`](../../../c3/s/simple_moving_average.c3) |
| C++ | [`cpp/s/simple_moving_average.cpp`](../../../cpp/s/simple_moving_average.cpp) |
| Elisa | [`elisa/s/simple_moving_average.elisa`](../../../elisa/s/simple_moving_average.elisa) |
| Nim | [`nim/s/simple_moving_average.nim`](../../../nim/s/simple_moving_average.nim) |
| Odin | [`odin/s/simple_moving_average.odin`](../../../odin/s/simple_moving_average.odin) |
| Rust | [`rust/s/simple_moving_average.rs`](../../../rust/s/simple_moving_average.rs) |
| V | [`v/s/simple_moving_average.v`](../../../v/s/simple_moving_average.v) |
| Zig | [`zig/s/simple_moving_average.zig`](../../../zig/s/simple_moving_average.zig) |

