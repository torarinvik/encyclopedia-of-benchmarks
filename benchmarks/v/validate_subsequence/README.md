# Validate subsequence

## Contract

This benchmark follows the pinned [TheAlgorithms/Dart `validate_subsequence.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/array/validate_subsequence.dart). The function checks whether a requested integer sequence appears in an integer array in the same order; matching values need not be adjacent.

Input is packed as `[array_length, sequence_length, array_values..., sequence_values...]`. Each length is in `0..4096`, the packed input contains exactly `2 + array_length + sequence_length` values, and every array or requested-sequence value is signed int32. Return 1 when the Dart predicate is true and 0 when false. Malformed packing, out-of-range values, or lengths above the bound return -1.

The pinned source checks `array.isEmpty` before checking `sequence.isEmpty`. Consequently, an empty source array returns false even when the requested sequence is also empty. For a nonempty source array, an empty requested sequence returns true. The remaining cases use a left-to-right greedy scan: on equality, advance the requested-sequence index; always advance the array index.

This preserves the array-oriented Dart candidate and its empty-source behavior. Related Rust `is_subsequence` and Go `IsSubsequence` sources implement the same greedy predicate for strings, but define empty sequence within empty input as true. They are not aliases under this exact edge contract. Longest common subsequence benchmarks return a length and solve a different output problem.

The nine ports use the existing `i64_array_scalar` ABI:

```c
int64_t validate_subsequence(const int64_t *values, size_t length);
```

The scan takes O(array length + sequence length) time including packed-input validation and O(1) extra space.

## Workload

`workload.json` covers successful and unsuccessful ordered matches, repeated values, the empty-sequence cases, empty source, exact equality, malformed packed lengths, and invalid values.
