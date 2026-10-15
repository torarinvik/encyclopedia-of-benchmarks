# Minimum of an integer sequence

Return the least value in a nonempty sequence, following the pinned Go `min.Int` and Lua variadic `min` implementations. Both initialize from the first value and replace it only when a later value is strictly smaller, so ties preserve the first occurrence.

## Contract

- Input is `[n, value_0, ..., value_(n-1)]`, where `n` is from 1 through 256.
- Values must fit signed 32-bit integers. Return the least value as a signed 64-bit scalar.
- Malformed input, an empty sequence, or an out-of-range value returns `INT64_MIN`, which cannot be a valid result in this contract.

[`workload.json`](workload.json) covers singleton sequences, mixed and negative values, ties, signed bounds, and invalid inputs.

| Language | Source |
| --- | --- |
| C | [`c/m/min.c`](../../../c/m/min.c) |
| C3 | [`c3/m/min.c3`](../../../c3/m/min.c3) |
| C++ | [`cpp/m/min.cpp`](../../../cpp/m/min.cpp) |
| Elisa | [`elisa/m/min.elisa`](../../../elisa/m/min.elisa) |
| Nim | [`nim/m/min.nim`](../../../nim/m/min.nim) |
| Odin | [`odin/m/min.odin`](../../../odin/m/min.odin) |
| Rust | [`rust/m/min.rs`](../../../rust/m/min.rs) |
| V | [`v/m/min.v`](../../../v/m/min.v) |
| Zig | [`zig/m/min.zig`](../../../zig/m/min.zig) |

The benchmark uses the `i64_array_scalar` ABI.
