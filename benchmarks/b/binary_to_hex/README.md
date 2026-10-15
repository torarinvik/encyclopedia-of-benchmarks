# Binary to hexadecimal

Convert a binary digit string to uppercase hexadecimal characters, preserving
the source's left-to-right nibble grouping and any leading zero groups.

## Contract

- The `i64_array_bytes_output` ABI represents the input as ASCII values `48`
  (`0`) and `49` (`1`), with length from 0 through 4,096.
- The source groups bits into four-bit nibbles from the right, pads only the
  most-significant partial group with zeroes, converts each group to `0-9` or
  `A-F`, then reverses the result. Output has no prefix and no NUL terminator.
- A valid call returns `ceil(input_length / 4)` and writes that many bytes.
  Empty input returns zero bytes; leading zero groups are preserved.
- Invalid lengths or non-binary input values return `-1`. An insufficient
  output buffer returns `-2`.
- Runtime is O(n); auxiliary space is O(1).

This follows the pinned [TheAlgorithms JavaScript `BinaryToHex.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/BinaryToHex.js)
on the bounded binary-string domain. The source does not validate malformed
characters; the benchmark excludes them so all nine implementations share a
well-defined input contract.

[`workload.json`](workload.json) covers the published example, partial
nibbles, preserved leading zero groups, empty input, and invalid values.

| Language | Source |
| --- | --- |
| C | [`c/b/binary_to_hex.c`](../../../c/b/binary_to_hex.c) |
| C3 | [`c3/b/binary_to_hex.c3`](../../../c3/b/binary_to_hex.c3) |
| C++ | [`cpp/b/binary_to_hex.cpp`](../../../cpp/b/binary_to_hex.cpp) |
| Elisa | [`elisa/b/binary_to_hex.elisa`](../../../elisa/b/binary_to_hex.elisa) |
| Nim | [`nim/b/binary_to_hex.nim`](../../../nim/b/binary_to_hex.nim) |
| Odin | [`odin/b/binary_to_hex.odin`](../../../odin/b/binary_to_hex.odin) |
| Rust | [`rust/b/binary_to_hex.rs`](../../../rust/b/binary_to_hex.rs) |
| V | [`v/b/binary_to_hex.v`](../../../v/b/binary_to_hex.v) |
| Zig | [`zig/b/binary_to_hex.zig`](../../../zig/b/binary_to_hex.zig) |

Build with the `i64_array_bytes_output` ABI family, for example:
`python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm binary_to_hex --language c`.
