# Longest repeating subsequence

Return the length of the longest subsequence that occurs twice in one ASCII input sequence. The two occurrences must use different positions.

## Contract

The packed input is `[n, ascii_values...]`, with `0 <= n <= 255`, each value in `0..127`, and exact length `n + 1`. Invalid input returns `-1`. The result is computed with the pinned Python recurrence: LCS of the sequence with itself, permitting a match only when the two positions differ. The ports use a fixed one-row DP buffer.

The benchmark uses the `i64_array_scalar` ABI family. Inputs cover empty, singleton, repeated, interleaved, and maximum-size sequences.
