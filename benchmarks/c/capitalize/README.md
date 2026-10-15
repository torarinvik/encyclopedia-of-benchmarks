# Capitalize the first ASCII letter

## Contract

Capitalize an ASCII byte string by converting its first lowercase English letter to uppercase. Leave all remaining bytes unchanged. Empty strings, uppercase initial letters, digits, spaces, punctuation, and control bytes are preserved. Inputs contain 0 through 256 ASCII bytes (values `0..127`). Invalid length or byte values return `-1`; insufficient output capacity returns `-2`; success returns the input length and writes the complete transformed string without a terminator.

This contract matches the pinned Python and F# sources over ASCII. Python uppercases the first character; F# changes it only when it is in `a..z`. Restricting the shared domain to ASCII removes Unicode casing and encoding differences. The existing `title_case_conversion` benchmark changes the starts of words; this one changes only the first character of the whole string.

The shared ABI is:

```c
int64_t capitalize(const int64_t *input, size_t length,
                   uint8_t *output, size_t output_capacity);
```

## Workload

[`workload.json`](workload.json) covers empty input, lowercase and uppercase starts, a digit, leading whitespace, punctuation, control bytes, invalid values, and the 256-byte boundary.

The shared byte-output runner validates the ASCII-byte array, copies it, and uppercases only an initial lowercase ASCII byte.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm capitalize --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm capitalize
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/capitalize.c`](../../../c/c/capitalize.c) |
| C3 | [`c3/c/capitalize.c3`](../../../c3/c/capitalize.c3) |
| C++ | [`cpp/c/capitalize.cpp`](../../../cpp/c/capitalize.cpp) |
| Elisa | [`elisa/c/capitalize.elisa`](../../../elisa/c/capitalize.elisa) |
| Nim | [`nim/c/capitalize.nim`](../../../nim/c/capitalize.nim) |
| Odin | [`odin/c/capitalize.odin`](../../../odin/c/capitalize.odin) |
| Rust | [`rust/c/capitalize.rs`](../../../rust/c/capitalize.rs) |
| V | [`v/c/capitalize.v`](../../../v/c/capitalize.v) |
| Zig | [`zig/c/capitalize.zig`](../../../zig/c/capitalize.zig) |

## Upstream references

- [F# `Capitalize.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/Capitalize.fs)
- [Python `capitalize.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/capitalize.py)
