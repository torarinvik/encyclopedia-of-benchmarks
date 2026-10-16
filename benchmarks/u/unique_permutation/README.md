# Unique permutations

Generate the distinct permutations of a string, even when characters repeat. The pinned Java method sorts its UTF-16 `char` array, then backtracks in ascending character order and skips a duplicate when the previous equal character is not currently used. This produces each distinct permutation once, in lexicographic order.

## Contract

- Input is `[n, ASCII_codepoints...]`, with `n` from 0 through 6 and exactly `n` codepoints in `[0,127]`.
- Output is the unique permutations in lexicographic order, each as a contiguous row of `n` ASCII bytes. Equal input characters are deduplicated in the output. The returned scalar is the number of rows.
- The empty string produces one empty permutation: return 1 and write zero bytes.
- Malformed packing or out-of-domain codepoints return `-1`. Output capacity below `n! × n` bytes, or a missing output buffer when bytes are required, returns `-2`.
- The maximum bound uses at most 720 rows and 4,320 output bytes. Restricting to ASCII keeps Java UTF-16 ordering identical to byte ordering.

## Source and related benchmarks

This follows the pinned Java [`UniquePermutation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/UniquePermutation.java). It returns an empty list for `null`; null has no packed-array representation. For a non-null empty string, the backtracking base case appends one empty string, so this benchmark preserves that behavior. The source sorts first and skips duplicate choices, unlike [`all_permutations`](../../a/all_permutations/README.md), which retains repeated rows and follows input-index order. The ASCII domain preserves the source's sorting and equality behavior on a portable bounded alphabet.

## Workload and ports

[`workload.json`](workload.json) covers the empty string, a repeated-character example, unsorted distinct characters, all-equal characters, embedded NUL, and invalid packing/domain cases. The shared `i64_array_bytes_output` ABI represents each output string as one fixed-width byte row.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm unique_permutation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm unique_permutation
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm unique_permutation --languages rust
```

| Language | Source |
| --- | --- |
| C | [`c/u/unique_permutation.c`](../../../c/u/unique_permutation.c) |
| C3 | [`c3/u/unique_permutation.c3`](../../../c3/u/unique_permutation.c3) |
| C++ | [`cpp/u/unique_permutation.cpp`](../../../cpp/u/unique_permutation.cpp) |
| Elisa | [`elisa/u/unique_permutation.elisa`](../../../elisa/u/unique_permutation.elisa) |
| Nim | [`nim/u/unique_permutation.nim`](../../../nim/u/unique_permutation.nim) |
| Odin | [`odin/u/unique_permutation.odin`](../../../odin/u/unique_permutation.odin) |
| Rust | [`rust/u/unique_permutation.rs`](../../../rust/u/unique_permutation.rs) |
| V | [`v/u/unique_permutation.v`](../../../v/u/unique_permutation.v) |
| Zig | [`zig/u/unique_permutation.zig`](../../../zig/u/unique_permutation.zig) |
