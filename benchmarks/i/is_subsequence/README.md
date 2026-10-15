# Is Subsequence

## Contract

Return whether a requested Unicode scalar sequence occurs in a main sequence in the same order. Values need not be adjacent. The scan is case-sensitive and performs no Unicode normalization.

The `i64_array_scalar` ABI receives packed input `[main_length, subsequence_length, main_codepoints..., subsequence_codepoints...]`. Each length is in `0..4096`; the packed input must contain exactly `2 + main_length + subsequence_length` values. Codepoints must be valid Unicode scalar values (`0..1,114,111`, excluding surrogates `55,296..57,343`). Return `1` for a match, `0` otherwise, and `-1` for malformed input.

This follows the pinned Rust `is_subsequence(sub, main)` implementation, which iterates Unicode `char`s and greedily advances the requested sequence when the current main character matches. In particular, the empty subsequence is true even when the main sequence is empty. The Dart array-based [`validate_subsequence`](../../v/validate_subsequence/README.md) benchmark returns false for that empty/empty case, so it has a separate contract.

## Workload

[`workload.json`](workload.json) covers empty sequences, successful and unsuccessful matches, repeated and interspersed values, supplementary-plane Unicode, combining marks without normalization, and malformed codepoints or packed lengths.

## Pinned source

- Rust [`is_subsequence.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/is_subsequence.rs)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_subsequence.c`](../../../c/i/is_subsequence.c) |
| C3 | [`c3/i/is_subsequence.c3`](../../../c3/i/is_subsequence.c3) |
| C++ | [`cpp/i/is_subsequence.cpp`](../../../cpp/i/is_subsequence.cpp) |
| Elisa | [`elisa/i/is_subsequence.elisa`](../../../elisa/i/is_subsequence.elisa) |
| Nim | [`nim/i/is_subsequence.nim`](../../../nim/i/is_subsequence.nim) |
| Odin | [`odin/i/is_subsequence.odin`](../../../odin/i/is_subsequence.odin) |
| Rust | [`rust/i/is_subsequence.rs`](../../../rust/i/is_subsequence.rs) |
| V | [`v/i/is_subsequence.v`](../../../v/i/is_subsequence.v) |
| Zig | [`zig/i/is_subsequence.zig`](../../../zig/i/is_subsequence.zig) |
