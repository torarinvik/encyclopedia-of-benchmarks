# Character-array left rotation

This benchmark follows the in-place `rotation(char[], int)` method in the pinned Java `Rotation` class. It rotates by reversing the prefix `[0,n-1]`, the suffix `[n,length-1]`, and then the full array. It is separate from the allocating `rotation(String, int)` method and the Python image rotation in the same source candidate.

## Contract

Input is a signed 64-bit array `[array_length, rotation_count, ASCII character bytes...]`. Array length is 0 through 256, every byte is ASCII 0 through 127, and rotation count is in `0..=array_length`. The packed length is exactly `2 + array_length`. The result is the rotated byte array.

Output is the rotated bytes with no terminator or length prefix. Empty arrays return length 0. Input validation precedes output-buffer checks: invalid input returns `-1`; otherwise a null or undersized output buffer returns `-2` without writing. Maximum output capacity is 256 bytes.

The independent [oracle](../../char_array_left_rotation_oracle.py) and [`workload.json`](workload.json) cover the Java example, empty/singleton arrays, boundary rotations, embedded NUL, maximum size, malformed input, and output-capacity behavior.

## Pinned source

- [TheAlgorithms/Java `Rotation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Rotation.java)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/char_array_left_rotation.c`](../../../c/c/char_array_left_rotation.c) |
| C3 | [`c3/c/char_array_left_rotation.c3`](../../../c3/c/char_array_left_rotation.c3) |
| C++ | [`cpp/c/char_array_left_rotation.cpp`](../../../cpp/c/char_array_left_rotation.cpp) |
| Elisa | [`elisa/c/char_array_left_rotation.elisa`](../../../elisa/c/char_array_left_rotation.elisa) |
| Nim | [`nim/c/char_array_left_rotation.nim`](../../../nim/c/char_array_left_rotation.nim) |
| Odin | [`odin/c/char_array_left_rotation.odin`](../../../odin/c/char_array_left_rotation.odin) |
| Rust | [`rust/c/char_array_left_rotation.rs`](../../../rust/c/char_array_left_rotation.rs) |
| V | [`v/c/char_array_left_rotation.v`](../../../v/c/char_array_left_rotation.v) |
| Zig | [`zig/c/char_array_left_rotation.zig`](../../../zig/c/char_array_left_rotation.zig) |
