# Array left rotation with modulo normalization

This benchmark follows the pinned Java `ArrayLeftRotation.rotateLeft` method. Nonpositive rotation counts return a copy in the original order; positive counts are reduced modulo the array length before a left rotation. Empty arrays remain empty.

## Contract

- Input is `[rotation_count, values...]`; the signed rotation count and every value are signed 32-bit integers, and there are 0..1,024 values.
- For `rotation_count <= 0`, return the original values. For a positive count and nonempty array, rotate left by `rotation_count % length`.
- Return the result as little-endian signed 32-bit values and return its element count. Return `-1` for malformed inputs and `-2` when the output buffer is too small.
- The method creates a new array in O(n) time and O(n) auxiliary space; the input is unchanged.

This is separate from [`array_left_rotation`](../array_left_rotation/README.md), whose pinned C++ source returns an empty vector when the shift is at least the array length.

| Language | Source |
| --- | --- |
| C | [`c/a/array_left_rotation_modulo.c`](../../../c/a/array_left_rotation_modulo.c) |
| C3 | [`c3/a/array_left_rotation_modulo.c3`](../../../c3/a/array_left_rotation_modulo.c3) |
| C++ | [`cpp/a/array_left_rotation_modulo.cpp`](../../../cpp/a/array_left_rotation_modulo.cpp) |
| Elisa | [`elisa/a/array_left_rotation_modulo.elisa`](../../../elisa/a/array_left_rotation_modulo.elisa) |
| Nim | [`nim/a/array_left_rotation_modulo.nim`](../../../nim/a/array_left_rotation_modulo.nim) |
| Odin | [`odin/a/array_left_rotation_modulo.odin`](../../../odin/a/array_left_rotation_modulo.odin) |
| Rust | [`rust/a/array_left_rotation_modulo.rs`](../../../rust/a/array_left_rotation_modulo.rs) |
| V | [`v/a/array_left_rotation_modulo.v`](../../../v/a/array_left_rotation_modulo.v) |
| Zig | [`zig/a/array_left_rotation_modulo.zig`](../../../zig/a/array_left_rotation_modulo.zig) |

Pinned Java source: [TheAlgorithms/Java `ArrayLeftRotation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/ArrayLeftRotation.java).

