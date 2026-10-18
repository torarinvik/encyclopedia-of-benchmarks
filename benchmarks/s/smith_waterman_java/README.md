# Smith–Waterman Java Scalar Score

This package preserves the pinned Java `SmithWaterman.align` API, which returns
only the best local alignment score. It is case-sensitive and keeps `-` as an
ordinary input character. The Python and Rust packages have separate contracts
because they return score matrices and apply different traceback rules.

## Contract

- Input is `[query_length, subject_length, match_score, mismatch_score,
  gap_score, query_ascii..., subject_ascii...]` in the signed 64-bit array ABI.
- Each sequence has 0 to 16 characters. Characters are ASCII letters or `-`.
  Match scores are 1 to 5; mismatch and gap scores are -5 to -1. Input length
  must equal `5 + query_length + subject_length`.
- Initialize the DP matrix to zero. For each pair, take the maximum of zero,
  diagonal plus match/mismatch score, above plus gap score, and left plus gap
  score. Return the greatest cell value; ties do not change the result.
- Return `-1` for malformed input. Empty sequences return zero.

The reference is the pinned Java [`SmithWaterman.align`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/SmithWaterman.java) method at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

[`workload.json`](workload.json) covers empty input, a local match, case
sensitivity, the ordinary hyphen character, malformed framing and character
values. Build with `i64_array_scalar` and record with
`benchmarks/run_i64_array_scalar.py`.
