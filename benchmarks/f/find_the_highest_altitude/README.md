# Find the highest altitude

Given consecutive altitude gains along a route, return the highest altitude reached. The route starts at altitude zero, and each input value changes altitude from one point to the next. The starting point counts as a candidate maximum, so an empty route or a route whose every prefix is negative returns zero.

## Contract

- The `i64_array_scalar` input is `[n, gains...]`, where `n` is 0..1024 and the packed array contains exactly `n` signed 32-bit gains.
- Accumulate gains in input order. Return the maximum of zero and every cumulative sum.
- Malformed packing or a gain outside the signed 32-bit range returns `-1`.
- The bound keeps every intermediate sum in signed 64-bit range. All valid results are nonnegative.

## Source and related algorithms

The pinned Ruby source is [`find_the_highest_altitude.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/find_the_highest_altitude.rb). It defines `largest_altitude` twice; the later definition is effective. That implementation initializes both current altitude and maximum altitude to zero, adds each gain in order, and retains the highest prefix including the starting point. [`prefix_sum`](../prefix_sum/README.md) returns or queries cumulative sums; this package returns only their maximum including the initial zero.

[`workload.json`](workload.json) covers empty input, positive and negative routes, the pinned examples, and invalid packing and values. The nine ports use the shared `i64_array_scalar` ABI. The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

| Language | Source |
| --- | --- |
| C | [`c/f/find_the_highest_altitude.c`](../../../c/f/find_the_highest_altitude.c) |
| C3 | [`c3/f/find_the_highest_altitude.c3`](../../../c3/f/find_the_highest_altitude.c3) |
| C++ | [`cpp/f/find_the_highest_altitude.cpp`](../../../cpp/f/find_the_highest_altitude.cpp) |
| Elisa | [`elisa/f/find_the_highest_altitude.elisa`](../../../elisa/f/find_the_highest_altitude.elisa) |
| Nim | [`nim/f/find_the_highest_altitude.nim`](../../../nim/f/find_the_highest_altitude.nim) |
| Odin | [`odin/f/find_the_highest_altitude.odin`](../../../odin/f/find_the_highest_altitude.odin) |
| Rust | [`rust/f/find_the_highest_altitude.rs`](../../../rust/f/find_the_highest_altitude.rs) |
| V | [`v/f/find_the_highest_altitude.v`](../../../v/f/find_the_highest_altitude.v) |
| Zig | [`zig/f/find_the_highest_altitude.zig`](../../../zig/f/find_the_highest_altitude.zig) |
