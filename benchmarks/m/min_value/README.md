# Minimum of two values

Return the smaller of two signed 32-bit integers, following the pinned Java [`MinValue.min`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/MinValue.java) comparison. Equal operands return that value.

## Contract

- Inputs are two signed 32-bit integers.
- Return `a` when `a <= b`, and otherwise return `b`.
- An operand outside the signed 32-bit range returns `-1`.

[`workload.json`](workload.json) covers negative, equal, mixed-sign, and signed-boundary operands.

| Language | Source |
| --- | --- |
| C | [`c/m/min_value.c`](../../../c/m/min_value.c) |
| C3 | [`c3/m/min_value.c3`](../../../c3/m/min_value.c3) |
| C++ | [`cpp/m/min_value.cpp`](../../../cpp/m/min_value.cpp) |
| Elisa | [`elisa/m/min_value.elisa`](../../../elisa/m/min_value.elisa) |
| Nim | [`nim/m/min_value.nim`](../../../nim/m/min_value.nim) |
| Odin | [`odin/m/min_value.odin`](../../../odin/m/min_value.odin) |
| Rust | [`rust/m/min_value.rs`](../../../rust/m/min_value.rs) |
| V | [`v/m/min_value.v`](../../../v/m/min_value.v) |
| Zig | [`zig/m/min_value.zig`](../../../zig/m/min_value.zig) |

The benchmark uses the `binary_scalar` ABI.
