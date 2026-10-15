# Check whether all characters are unique

Return whether every character in the input string occurs at most once, preserving the pinned Python routine's case-sensitive bitset behavior.

## Contract

- The `i64_array_scalar` ABI encodes a string as ASCII code values from 0 through 127, with at most 4,096 values.
- Return `1` if every value is unique, including `1` for an empty input; return `0` when a repeated value occurs.
- The comparison is case-sensitive and includes spaces, punctuation, NUL, and control values in the selected ASCII domain.
- Values outside `0..127` or inputs longer than 4,096 return `-1`.

The source sets one bit per Unicode code point and returns false as soon as a bit is already set. Two 64-bit words cover the benchmark's bounded ASCII set and preserve that duplicate check. This differs from the case-insensitive `isogram` benchmark, which applies its own letter-focused normalization.

## Workload and implementations

[`workload.json`](workload.json) covers empty strings, the published example, case differences, repeated spaces and punctuation, embedded NUL, all 128 ASCII values, and invalid codes. The package uses the array-scalar ABI.

| Language | Source |
| --- | --- |
| C | [`c/i/is_contains_unique_chars.c`](../../../c/i/is_contains_unique_chars.c) |
| C3 | [`c3/i/is_contains_unique_chars.c3`](../../../c3/i/is_contains_unique_chars.c3) |
| C++ | [`cpp/i/is_contains_unique_chars.cpp`](../../../cpp/i/is_contains_unique_chars.cpp) |
| Elisa | [`elisa/i/is_contains_unique_chars.elisa`](../../../elisa/i/is_contains_unique_chars.elisa) |
| Nim | [`nim/i/is_contains_unique_chars.nim`](../../../nim/i/is_contains_unique_chars.nim) |
| Odin | [`odin/i/is_contains_unique_chars.odin`](../../../odin/i/is_contains_unique_chars.odin) |
| Rust | [`rust/i/is_contains_unique_chars.rs`](../../../rust/i/is_contains_unique_chars.rs) |
| V | [`v/i/is_contains_unique_chars.v`](../../../v/i/is_contains_unique_chars.v) |
| Zig | [`zig/i/is_contains_unique_chars.zig`](../../../zig/i/is_contains_unique_chars.zig) |

## Pinned source

- [TheAlgorithms Python `is_contains_unique_chars.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/is_contains_unique_chars.py)
