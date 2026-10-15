# Shortest common supersequence length

This benchmark returns the length of the shortest string that contains both input sequences as subsequences. The pinned Java routine fills a bottom-up longest-common-subsequence table, then returns left_length + right_length - lcs_length.

## Contract

- The i64_array_scalar input packs both sequences as [left_length, right_length, left_values..., right_values...].
- Each length is in 0..=255, each value is an ASCII value in 0..=127, and the array contains exactly 2 + left_length + right_length values.
- The result is the shortest common supersequence length. Malformed or out-of-domain input returns -1.
- Empty sequences are valid. One empty input returns the other sequence's length; two empty inputs return zero.
- The full dynamic-programming table has at most 256 × 256 cells, and the result fits the Java source's int type.

The ASCII restriction makes byte lengths agree with Java's UTF-16 code-unit lengths. This package is distinct from longest_common_subsequence, which returns the length of a shared subsequence, and from the sequence-producing shortest_common_supersequence candidate.

The shared `i64_array_scalar` runner validates workload results with the same full-table LCS recurrence and derives the supersequence length as `m + n - LCS`.

## Inspected upstream source

- [TheAlgorithms/Java — ShortestCommonSupersequenceLength.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/ShortestCommonSupersequenceLength.java)

At this pinned revision, shortestSuperSequence computes LCS with a full two-dimensional table and returns the sum of input lengths minus the final LCS cell. The zero-valued table boundary gives the stated empty-input behavior.

The nine ports are in the s/ source folders for C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig. They expose the i64_array_scalar ABI.

