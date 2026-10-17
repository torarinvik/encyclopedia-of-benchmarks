# String left rotation

This benchmark follows the allocating `rotation(String, int)` overload in the
pinned Java `Rotation` class. It returns `s.substring(n) + s.substring(0, n)`.
This is separate from the class's in-place `rotation(char[], int)` overload
and from the Python affine image-rotation source matched to the same filename.

## Contract

Input is a signed 64-bit array `[string_length, rotation_count, UTF-16 code
units...]`. The string length is 0 through 256, the rotation count is in
`0..=string_length`, and each code unit is 0 through 65,535. The packed length
is exactly `2 + string_length`. Rotation counts index Java UTF-16 code units,
not Unicode code points, so a valid rotation can split a surrogate pair.

The result is the new left-rotated string serialized as two little-endian bytes
per UTF-16 code unit, with no terminator or length prefix. Rotation counts zero
and the full string length return the original code-unit sequence; an empty
string with count zero is valid. Input validation precedes output-buffer checks:
malformed input returns `-1`; valid nonempty output with a null or undersized
output buffer returns `-2` without writing. An empty result succeeds with
length zero even when the output pointer is null, because no bytes need to be
written. Output is at most 512 bytes. The source allocates through substring
concatenation; the benchmark compares the returned contents and does not expose
object identity.

[`workload.json`](workload.json) covers the pinned example, empty and singleton
strings, boundary counts, embedded NUL, surrogate pairs and lone surrogates,
maximum length, malformed input, and trailing values. Its ABI cases cover
null input, empty and nonempty null output, short and exact output capacity,
and invalid-input precedence. The independent oracle is
[`benchmarks/string_left_rotation_oracle.py`](../../string_left_rotation_oracle.py).

## Pinned source

[TheAlgorithms/Java `Rotation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Rotation.java)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm string_left_rotation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm string_left_rotation
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm string_left_rotation
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/string_left_rotation.c`](../../../c/s/string_left_rotation.c) |
| C3 | [`c3/s/string_left_rotation.c3`](../../../c3/s/string_left_rotation.c3) |
| C++ | [`cpp/s/string_left_rotation.cpp`](../../../cpp/s/string_left_rotation.cpp) |
| Elisa | [`elisa/s/string_left_rotation.elisa`](../../../elisa/s/string_left_rotation.elisa) |
| Nim | [`nim/s/string_left_rotation.nim`](../../../nim/s/string_left_rotation.nim) |
| Odin | [`odin/s/string_left_rotation.odin`](../../../odin/s/string_left_rotation.odin) |
| Rust | [`rust/s/string_left_rotation.rs`](../../../rust/s/string_left_rotation.rs) |
| V | [`v/s/string_left_rotation.v`](../../../v/s/string_left_rotation.v) |
| Zig | [`zig/s/string_left_rotation.zig`](../../../zig/s/string_left_rotation.zig) |
