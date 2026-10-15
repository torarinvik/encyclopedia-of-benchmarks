# Streaming moving average

This package ports the pinned [TheAlgorithms/Python streaming calculator](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/streaming_moving_average.py). Each update appends one value to a bounded trailing window and reports the average of the values currently in the window. Early results average the partial window, as in the source.

The `i64_array_bytes_output` ABI packs `[window_size, n, values[0..n]]`. The benchmarked domain is `1 <= window_size <= 256`, `1 <= n <= 256`, with signed 32-bit integer values (a bounded subset of the source's floating-point values). It returns `n` little-endian IEEE-754 binary64 results. Invalid input returns `-1`; insufficient output capacity returns `-2`; success returns `8*n`.

Each result is computed as the exact integer sum of the current trailing window divided by its current length, matching the source's `sum(self.window) / len(self.window)` on this domain. Runtime is `O(n * window_size)` and auxiliary space is `O(1)` beyond the output buffer.

## Workload

[`workload.json`](workload.json) covers the upstream examples, a window of one, a window longer than the input, negative values, and malformed/out-of-range inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/streaming_moving_average.c`](../../../c/s/streaming_moving_average.c) |
| C3 | [`c3/s/streaming_moving_average.c3`](../../../c3/s/streaming_moving_average.c3) |
| C++ | [`cpp/s/streaming_moving_average.cpp`](../../../cpp/s/streaming_moving_average.cpp) |
| Elisa | [`elisa/s/streaming_moving_average.elisa`](../../../elisa/s/streaming_moving_average.elisa) |
| Nim | [`nim/s/streaming_moving_average.nim`](../../../nim/s/streaming_moving_average.nim) |
| Odin | [`odin/s/streaming_moving_average.odin`](../../../odin/s/streaming_moving_average.odin) |
| Rust | [`rust/s/streaming_moving_average.rs`](../../../rust/s/streaming_moving_average.rs) |
| V | [`v/s/streaming_moving_average.v`](../../../v/s/streaming_moving_average.v) |
| Zig | [`zig/s/streaming_moving_average.zig`](../../../zig/s/streaming_moving_average.zig) |
