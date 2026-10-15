# Maximum of an integer sequence

Return the greatest value in a nonempty sequence, following the pinned Go `max.Int` and Lua variadic `max` implementations. Both initialize from the first value and replace it only when a later value is strictly greater, so ties preserve the first occurrence.

## Contract

- Input is `[n, value_0, ..., value_(n-1)]`, where `n` is from 1 through 256.
- Values must fit signed 32-bit integers. Return the greatest value as a signed 64-bit scalar.
- Malformed input, an empty sequence, or an out-of-range value returns `INT64_MIN`, which cannot be a valid result in this contract.

[`workload.json`](workload.json) covers singleton sequences, mixed and negative values, ties, signed bounds, and invalid inputs.

| Language | Source |
| --- | --- |
| C | [`c/m/max.c`](../../../c/m/max.c) |
| C3 | [`c3/m/max.c3`](../../../c3/m/max.c3) |
| C++ | [`cpp/m/max.cpp`](../../../cpp/m/max.cpp) |
| Elisa | [`elisa/m/max.elisa`](../../../elisa/m/max.elisa) |
| Nim | [`nim/m/max.nim`](../../../nim/m/max.nim) |
| Odin | [`odin/m/max.odin`](../../../odin/m/max.odin) |
| Rust | [`rust/m/max.rs`](../../../rust/m/max.rs) |
| V | [`v/m/max.v`](../../../v/m/max.v) |
| Zig | [`zig/m/max.zig`](../../../zig/m/max.zig) |

The benchmark uses the `i64_array_scalar` ABI.
