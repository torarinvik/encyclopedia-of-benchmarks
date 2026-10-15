# Array right rotation

This benchmark follows the pinned C++ `shift_right` function. It creates a new array with the final `shift` values moved to the front, and leaves the input unchanged. If `shift` is at least the array length, the source returns an empty vector.

## Contract

- The input is `[shift, values...]`; `shift` is from 0 through 1,024 and there are 0 through 1,024 signed 32-bit values.
- When `shift < length`, return the right-rotated values. When `shift >= length`, return an empty result. This includes empty arrays.
- Encode output elements as little-endian signed 32-bit integers and return the element count. Invalid inputs return `-1`; insufficient output capacity returns `-2`.
- The benchmark writes to a separate output buffer, so input remains unchanged. The operation takes O(n) time and O(n) auxiliary space.

The pinned C++ sources from [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/array_right_rotation.cpp) and [C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/array_right_rotation.cpp) implement the same rightward copy and empty-result boundary. The Java [`ArrayRightRotation`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/ArrayRightRotation.java) instead mutates its input and reduces nonnegative shifts modulo the length; this benchmark uses the C++ behavior.

This is distinct from [`array_left_rotation`](../array_left_rotation/README.md), which moves the prefix to the end, and [`array_left_rotation_modulo`](../array_left_rotation_modulo/README.md), which uses Java's modulo rule. The existing [`rotate_array`](../../r/rotate_array/README.md) also rotates right, but repeats single-place shifts and wraps shifts greater than the length instead of returning an empty result. [`rotate_array_reversal`](../../r/rotate_array_reversal/README.md) supports signed steps and modulo normalization.

[`workload.json`](workload.json) covers both rotation directions' edge sizes, the empty boundary, signed values, invalid inputs, and the maximum supported array length.

| Language | Source |
| --- | --- |
| C | [`c/a/array_right_rotation.c`](../../../c/a/array_right_rotation.c) |
| C3 | [`c3/a/array_right_rotation.c3`](../../../c3/a/array_right_rotation.c3) |
| C++ | [`cpp/a/array_right_rotation.cpp`](../../../cpp/a/array_right_rotation.cpp) |
| Elisa | [`elisa/a/array_right_rotation.elisa`](../../../elisa/a/array_right_rotation.elisa) |
| Nim | [`nim/a/array_right_rotation.nim`](../../../nim/a/array_right_rotation.nim) |
| Odin | [`odin/a/array_right_rotation.odin`](../../../odin/a/array_right_rotation.odin) |
| Rust | [`rust/a/array_right_rotation.rs`](../../../rust/a/array_right_rotation.rs) |
| V | [`v/a/array_right_rotation.v`](../../../v/a/array_right_rotation.v) |
| Zig | [`zig/a/array_right_rotation.zig`](../../../zig/a/array_right_rotation.zig) |
