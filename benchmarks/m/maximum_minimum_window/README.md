# Maximum of minimums for every window size

For each window width from 1 through the input length, return the largest minimum value among all windows of that width. The pinned Java source finds each element's previous and next strictly smaller elements with monotone stacks, assigns its value to the maximum width it can represent, then propagates maxima to smaller widths.

## Contract

Input is `[n, values...]` in the `i64_array_bytes_output` ABI. `n` is 1 through 256, the vector has exactly `n` entries, and each value is in `[0,1,000,000]`. Nonnegative values preserve the Java implementation's zero-initialized answer-array semantics. Output is `n` little-endian signed i64 values in ascending window-width order. Success returns `n`; invalid input returns `-2`; insufficient output capacity returns `-3`.

Pinned source: [TheAlgorithms/Java `MaximumMinimumWindow.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/MaximumMinimumWindow.java).

[`workload.json`](workload.json) covers the pinned example, duplicates and zero, increasing input, a single value, and invalid cases. The runtime oracle is [`benchmarks/maximum_minimum_window_oracle.py`](../../maximum_minimum_window_oracle.py).

| Language | Port |
|---|---|
| C | [`c/m/maximum_minimum_window.c`](../../../c/m/maximum_minimum_window.c) |
| C3 | [`c3/m/maximum_minimum_window.c3`](../../../c3/m/maximum_minimum_window.c3) |
| C++ | [`cpp/m/maximum_minimum_window.cpp`](../../../cpp/m/maximum_minimum_window.cpp) |
| Elisa | [`elisa/m/maximum_minimum_window.elisa`](../../../elisa/m/maximum_minimum_window.elisa) |
| Nim | [`nim/m/maximum_minimum_window.nim`](../../../nim/m/maximum_minimum_window.nim) |
| Odin | [`odin/m/maximum_minimum_window.odin`](../../../odin/m/maximum_minimum_window.odin) |
| Rust | [`rust/m/maximum_minimum_window.rs`](../../../rust/m/maximum_minimum_window.rs) |
| V | [`v/m/maximum_minimum_window.v`](../../../v/m/maximum_minimum_window.v) |
| Zig | [`zig/m/maximum_minimum_window.zig`](../../../zig/m/maximum_minimum_window.zig) |
