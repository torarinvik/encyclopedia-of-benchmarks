# Damerau–Levenshtein distance

This benchmark computes the unrestricted Damerau–Levenshtein edit distance between two ASCII byte strings. The selected authoritative source is the Java implementation: it tracks each character's last row and the most recent matching column while filling a sentinel-padded dynamic-programming table. Its transposition operation can combine with later edits to the same substring.

## Contract

- The `i64_array_scalar` input is `[left_length, right_length, left_bytes..., right_bytes...]`.
- Each length is 0..32. Every byte is 0..127, and the packed input must contain exactly `2 + left_length + right_length` values.
- The result is the minimum number of insertions, deletions, substitutions, and adjacent transpositions under the unrestricted Damerau–Levenshtein metric. Empty strings are valid.
- Malformed or out-of-domain input returns `-1`.
- The benchmark uses a fixed 34×34 table and a 128-entry last-position table. It does not allocate memory or modify the input.

The ASCII domain makes Java's UTF-16 code units and byte indexing identical. The authoritative source is [Java `DamerauLevenshteinDistance.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/DamerauLevenshteinDistance.java), pinned at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. Its implementation updates the current matching column before evaluating the transposition candidate. That ordering makes the pinned Java method return 0 for `"aa"` to `"a"`, although the unrestricted distance is 1. This benchmark corrects that source bug by using the previous matching column in the candidate, preserving the standard unrestricted metric; the workload includes this case. The catalog also contains [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/damerau_levenshtein_distance.py) (`e1a2a8b016001309a73d5fec4818c35cca139795`) and [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/DamerauLevenshteinDistance.cs) (`96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`) variants. Those use the restricted optimal string alignment recurrence and can return different distances; they are documented as behaviorally different variants and do not define this package's oracle. The standard [`levenshtein_distance`](../../l/levenshtein_distance/README.md) package supports only insertion, deletion, and substitution.

## Workload

`workload.json` covers empty strings, equality, insertion/deletion/substitution, adjacent transposition, repeated characters, the unrestricted `CA` to `ABC` case, the repeated-character source-correction case, and maximum-length inputs.

## Run

The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py). Build with the `i64_array_scalar` ABI family and record with that runner.
