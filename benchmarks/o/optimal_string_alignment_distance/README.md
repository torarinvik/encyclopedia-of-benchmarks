# Optimal string alignment distance

This benchmark computes the restricted Damerau–Levenshtein distance, also called optimal string alignment (OSA) distance. It follows the pinned Python and C# implementations: dynamic programming with unit insertion, deletion, and substitution costs, plus a single adjacent transposition candidate when the current character pair cross-matches. The recurrence restricts reuse of edits on the same substring.

## Contract

- The `i64_array_scalar` input is `[left_length, right_length, left_bytes..., right_bytes...]`.
- Each length is 0..32. Every byte is 0..127, and the packed input must contain exactly `2 + left_length + right_length` values.
- The result is the OSA edit distance. Empty strings are valid.
- Malformed or out-of-domain input returns `-1`.
- The implementation uses a fixed 34×34 dynamic-programming table, does not allocate memory, and does not modify the input.

The authoritative behavior is shared by the pinned [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/damerau_levenshtein_distance.py) source at `e1a2a8b016001309a73d5fec4818c35cca139795` and [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/DamerauLevenshteinDistance.cs) at `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`. The pinned C# [`OptimalStringAlignment.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/OptimalStringAlignment.cs) is corroborating source. Its `dp[i-2][j-2] + cost` transposition rule is restricted: for `CA` → `ABC`, OSA returns 3 while unrestricted full Damerau–Levenshtein returns 2. The latter is benchmarked separately in [`damerau_levenshtein_distance`](../../d/damerau_levenshtein_distance/README.md). Plain [`levenshtein_distance`](../../l/levenshtein_distance/README.md) does not allow transpositions and returns 2 for `ab` → `ba`.

The ASCII domain makes Java-style UTF-16 code units and byte indexing identical and avoids Unicode normalization differences.

## Workload

`workload.json` covers empty inputs, equal strings, each edit kind, ordinary adjacent transposition, the OSA/full Damerau distinguishing case, repeated bytes, and inputs at the maximum supported length.

## Run

The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py). Build with the `i64_array_scalar` ABI family and record with that runner.
