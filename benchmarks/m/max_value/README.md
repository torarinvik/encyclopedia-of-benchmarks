# Maximum of two values

Return the larger of two signed 32-bit integers, following the pinned Java [`MaxValue.max`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/MaxValue.java) comparison. Equal operands return that value.

## Contract

- Inputs are two signed 32-bit integers.
- Return `a` when `a >= b`, and otherwise return `b`.
- An operand outside the signed 32-bit range returns `-1`.

[`workload.json`](workload.json) covers negative, equal, mixed-sign, and signed-boundary operands.

| Language | Source |
| --- | --- |
| C | [`c/m/max_value.c`](../../../c/m/max_value.c) |
| C3 | [`c3/m/max_value.c3`](../../../c3/m/max_value.c3) |
| C++ | [`cpp/m/max_value.cpp`](../../../cpp/m/max_value.cpp) |
| Elisa | [`elisa/m/max_value.elisa`](../../../elisa/m/max_value.elisa) |
| Nim | [`nim/m/max_value.nim`](../../../nim/m/max_value.nim) |
| Odin | [`odin/m/max_value.odin`](../../../odin/m/max_value.odin) |
| Rust | [`rust/m/max_value.rs`](../../../rust/m/max_value.rs) |
| V | [`v/m/max_value.v`](../../../v/m/max_value.v) |
| Zig | [`zig/m/max_value.zig`](../../../zig/m/max_value.zig) |

The benchmark uses the `binary_scalar` ABI.
