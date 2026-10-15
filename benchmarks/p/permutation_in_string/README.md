# Permutation in String

The pinned C LeetCode 567 source tracks letter-count differences for the current text window and updates the number of mismatched letters as the window moves. The JavaScript `PermutationinString` candidate uses the same sliding-window comparison. The nine local ports share the fixed 26-letter frequency window and do not allocate per call.

## Contract

- The packed input is `[pattern_length, text_length, pattern_ascii_values..., text_ascii_values...]`.
- Both strings contain 0–1,024 lowercase ASCII letters (`a` to `z`). The packed length must match the two declared lengths.
- Return `1` if some contiguous text window is a permutation of the pattern, `0` if no such window exists, and `-1` for malformed input or characters outside the lowercase ASCII domain.
- An empty pattern matches every text, including an empty text. A longer pattern than text returns `0`.
- The algorithm uses O(pattern length + text length) time and O(1) extra space, with a 26-entry frequency table.

Run `python3 benchmarks/verify_permutation_in_string.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against exhaustive short-string pairs, seeded random inputs, boundary cases, malformed inputs, and the published workload.

## Inspected upstream sources

- [C — LeetCode `567.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/567.c)
- [JavaScript — `PermutationinString.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/PermutationinString.js)
