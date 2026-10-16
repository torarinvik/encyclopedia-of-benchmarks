# Jaro similarity

This benchmark ports the pinned C# `JaroSimilarity.Calculate` routine. Input is `[s1_length, s1_codepoints..., s2_length, s2_codepoints...]`; both strings contain ASCII code units from 0 through 127, each has length at most 32, and `s1` must be at least as long as `s2`. The latter restriction avoids an out-of-range access in the pinned implementation, which loops over the longer string while indexing `s1`.

The matcher uses `max(longer_length/2 - 1, 0)` as its matching window, tracks matched positions, counts transpositions in matched-character order, halves that count with integer division, and evaluates the source Jaro formula. Equal strings, including two empty strings, return 1. Invalid input returns `-1e300`; valid output is binary64. See the [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/Similarity/JaroSimilarity.cs).
