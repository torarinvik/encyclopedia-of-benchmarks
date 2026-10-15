# Longest common substring

Return the length of the longest contiguous substring shared by two strings. The benchmark measures the length because the pinned Dart and Rust functions return a length, while Java and Python return a substring whose tie-breaking can differ.

## Contract

The `i64_array_scalar` input is `[length_a, ASCII codes for A..., length_b, ASCII codes for B...]`. Each length is 0 through 256, the packed array must have exactly `length_a + length_b + 2` values, and every character code must be printable ASCII 32 through 126. Return the maximum number of consecutive matching characters. Empty strings or no match return 0. Malformed lengths or character values return `-1`.

Restricting inputs to printable ASCII gives the same character units for Dart/Java UTF-16, Python Unicode code points, and Rust UTF-8 bytes. The implementations use the dynamic-programming recurrence `dp[i][j] = dp[i-1][j-1] + 1` on a character match and zero otherwise. A descending one-row update preserves the recurrence in O(min(n,m)) additional space.

Pinned sources: [Dart `longest_common_substring.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/dynamic_programming/longest_common_substring.dart), [Java `LongestCommonSubstring.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/LongestCommonSubstring.java), [Python `longest_common_substring.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/longest_common_substring.py), and [Rust `longest_common_substring.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/longest_common_substring.rs).

## Workload and implementations

The workload includes source examples, multiple equal-length answers, punctuation, case sensitivity, empty inputs, maximum-length strings, and malformed encodings.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm longest_common_substring --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/l/longest_common_substring/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/l/longest_common_substring.c`](../../../c/l/longest_common_substring.c) |
| C3 | [`c3/l/longest_common_substring.c3`](../../../c3/l/longest_common_substring.c3) |
| C++ | [`cpp/l/longest_common_substring.cpp`](../../../cpp/l/longest_common_substring.cpp) |
| Elisa | [`elisa/l/longest_common_substring.elisa`](../../../elisa/l/longest_common_substring.elisa) |
| Nim | [`nim/l/longest_common_substring.nim`](../../../nim/l/longest_common_substring.nim) |
| Odin | [`odin/l/longest_common_substring.odin`](../../../odin/l/longest_common_substring.odin) |
| Rust | [`rust/l/longest_common_substring.rs`](../../../rust/l/longest_common_substring.rs) |
| V | [`v/l/longest_common_substring.v`](../../../v/l/longest_common_substring.v) |
| Zig | [`zig/l/longest_common_substring.zig`](../../../zig/l/longest_common_substring.zig) |
