# Median of a growing integer stream

The pinned Java implementation maintains a max-heap for the lower half and a min-heap for the upper half. It inserts into one heap, rebalances until their sizes differ by at most one, and reports the larger heap’s root or the average of both roots when their sizes match. The integer specialization calculates an even-size median as `(a+b)/2`, which truncates toward zero.

## Contract

Input is `[n, values...]` in the `i64_array_bytes_output` ABI. `n` is 1 through 256, the stream has exactly `n` values, and values are in `[-1,000,000,1,000,000]`. Output is one signed little-endian i64 median after each insertion. Invalid input returns `-1`; insufficient output capacity returns `-2`; success returns the number of bytes written (`n*8`). The value bound keeps the source’s integer sum within range.

Pinned source: [TheAlgorithms/Java `MedianOfRunningArray.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java) and [integer specialization](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayInteger.java). [`workload.json`](workload.json) covers ascending and negative streams, duplicates, one element, and malformed input. Runtime oracle: [`benchmarks/median_of_running_array_integer_oracle.py`](../../median_of_running_array_integer_oracle.py).

| Language | Port |
|---|---|
| C | [`c/m/median_of_running_array_integer.c`](../../../c/m/median_of_running_array_integer.c) |
| C3 | [`c3/m/median_of_running_array_integer.c3`](../../../c3/m/median_of_running_array_integer.c3) |
| C++ | [`cpp/m/median_of_running_array_integer.cpp`](../../../cpp/m/median_of_running_array_integer.cpp) |
| Elisa | [`elisa/m/median_of_running_array_integer.elisa`](../../../elisa/m/median_of_running_array_integer.elisa) |
| Nim | [`nim/m/median_of_running_array_integer.nim`](../../../nim/m/median_of_running_array_integer.nim) |
| Odin | [`odin/m/median_of_running_array_integer.odin`](../../../odin/m/median_of_running_array_integer.odin) |
| Rust | [`rust/m/median_of_running_array_integer.rs`](../../../rust/m/median_of_running_array_integer.rs) |
| V | [`v/m/median_of_running_array_integer.v`](../../../v/m/median_of_running_array_integer.v) |
| Zig | [`zig/m/median_of_running_array_integer.zig`](../../../zig/m/median_of_running_array_integer.zig) |
