# Valid Anagram

This benchmark checks whether two lowercase ASCII strings contain the same letters with the same frequencies. It ports the frequency-table algorithm from [TheAlgorithms/C LeetCode 242](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/242.c), which counts both strings over the 26 lowercase English letters and compares those counts.

## Contract

- The packed input is `[first_length, second_length, first_ascii_values..., second_ascii_values...]`.
- Each string may contain 0 through 1,024 lowercase ASCII letters (`a` to `z`). The packed input length must match both declared lengths.
- Return `1` when the strings are anagrams, or `0` when their letter frequencies differ. Two empty strings are anagrams.
- Malformed lengths or out-of-domain characters return `-1`. The input is not modified.
- Runtime is O(n + m); the 26-entry frequency tables use O(1) extra space.

The numeric LeetCode source stem `242` is recorded as the algorithm name `valid_anagram` in the language folders and catalog.

Run `python3 benchmarks/verify_valid_anagram.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against exhaustive short-string pairs, random inputs, boundaries, malformed inputs, and the published workload.

## Inspected upstream source

- [C — LeetCode `242.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/242.c)
