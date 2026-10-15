# Array right rotation with modulo normalization

This benchmark follows the pinned Java `ArrayRightRotation.rotateRight` method. The method reduces nonnegative `k` modulo the array length and rotates the values right. It reverses the input array in place; the shared ABI returns the resulting values through a separate output buffer.

## Contract

- Input is `[shift, values...]`; `shift` is a nonnegative signed 32-bit integer and values are signed 32-bit integers. Array length is 1..1024.
- For a nonempty array, rotate right by `rotation_count % array length`.
- Empty arrays and negative shifts are invalid, matching the source exception domain.
- Return the values as little-endian signed 32-bit integers in a separate output buffer and return the output element count. Return `-1` for malformed lengths, shifts, or values, and `-2` when the output buffer is too small.
- The Java source throws for negative shifts and empty arrays; the shared ABI uses -1 for invalid inputs. The input buffer remains unchanged at the shared ABI boundary. The algorithm uses O(n) time and O(n) auxiliary space.

## Workload

[`workload.json`](workload.json) covers zero and positive shifts, boundary shifts, signed values, invalid inputs, and the maximum supported array length.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/array_right_rotation_modulo.c`](../../../c/a/array_right_rotation_modulo.c) |
| C3 | [`c3/a/array_right_rotation_modulo.c3`](../../../c3/a/array_right_rotation_modulo.c3) |
| C++ | [`cpp/a/array_right_rotation_modulo.cpp`](../../../cpp/a/array_right_rotation_modulo.cpp) |
| Elisa | [`elisa/a/array_right_rotation_modulo.elisa`](../../../elisa/a/array_right_rotation_modulo.elisa) |
| Nim | [`nim/a/array_right_rotation_modulo.nim`](../../../nim/a/array_right_rotation_modulo.nim) |
| Odin | [`odin/a/array_right_rotation_modulo.odin`](../../../odin/a/array_right_rotation_modulo.odin) |
| Rust | [`rust/a/array_right_rotation_modulo.rs`](../../../rust/a/array_right_rotation_modulo.rs) |
| V | [`v/a/array_right_rotation_modulo.v`](../../../v/a/array_right_rotation_modulo.v) |
| Zig | [`zig/a/array_right_rotation_modulo.zig`](../../../zig/a/array_right_rotation_modulo.zig) |

Pinned source: [Java `rotateRight`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/ArrayRightRotation.java).
