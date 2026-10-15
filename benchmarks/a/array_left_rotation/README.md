# Array left rotation

This benchmark follows the pinned C++ `shift_left` routine, which creates a new vector with the first `shift` values moved to the end. It returns an empty vector when `shift >= array.size()`; it does not reduce the shift modulo the length. The result is returned in a separate byte buffer, leaving the input unchanged.

The same-name Java candidate has different behavior: it leaves the array unchanged for nonpositive shifts and reduces positive shifts modulo the array length. This package uses the pinned C++ contract; the Java behavior is not folded into that workload.

## Contract

- The input is `[shift, values...]`; `shift` is in 0..1,024 and there are 0..1,024 signed 32-bit values.
- If `shift < array length`, return the left-rotated values as little-endian signed 32-bit integers and return the value count. If `shift >= array length`, return an empty result and count 0.
- Return `-1` for invalid lengths, shifts, or values, and `-2` when the output buffer is too small.
- The input remains unchanged. The copy takes O(n) time and O(n) auxiliary space.

[`workload.json`](workload.json) covers empty and single-element arrays, shift boundaries, signed values, invalid inputs, and the maximum supported array length.

| Language | Source |
| --- | --- |
| C | [`c/a/array_left_rotation.c`](../../../c/a/array_left_rotation.c) |
| C3 | [`c3/a/array_left_rotation.c3`](../../../c3/a/array_left_rotation.c3) |
| C++ | [`cpp/a/array_left_rotation.cpp`](../../../cpp/a/array_left_rotation.cpp) |
| Elisa | [`elisa/a/array_left_rotation.elisa`](../../../elisa/a/array_left_rotation.elisa) |
| Nim | [`nim/a/array_left_rotation.nim`](../../../nim/a/array_left_rotation.nim) |
| Odin | [`odin/a/array_left_rotation.odin`](../../../odin/a/array_left_rotation.odin) |
| Rust | [`rust/a/array_left_rotation.rs`](../../../rust/a/array_left_rotation.rs) |
| V | [`v/a/array_left_rotation.v`](../../../v/a/array_left_rotation.v) |
| Zig | [`zig/a/array_left_rotation.zig`](../../../zig/a/array_left_rotation.zig) |

Pinned source: [TheAlgorithms/C-Plus-Plus `array_left_rotation.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/array_left_rotation.cpp).

