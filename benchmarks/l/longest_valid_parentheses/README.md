# Longest Valid Parentheses

The pinned C LeetCode implementation uses a memoized endpoint recurrence. The nine portable ports evaluate the same recurrence bottom-up, scanning from right to left so every suffix result is ready before it is used. This keeps the linear-time method while avoiding recursion-depth dependence.

## Contract

- Input is an array of 0–4,096 signed 64-bit values encoding ASCII `(` as 40 and `)` as 41.
- Return the length of the longest contiguous, well-formed parenthesis substring. Return 0 when none exists, including empty input.
- Return `-1` for a value other than 40 or 41, or for an input longer than 4,096 values.
- The implementation uses O(n) time and O(n) fixed local storage. It is integer-only and uses portable language features.

## Workload and verification

[`workload.json`](workload.json) covers empty and invalid inputs, nested and adjacent pairs, unmatched boundaries, and maximum-length alternating and nested sequences. [`benchmarks/verify_longest_valid_parentheses.py`](../../verify_longest_valid_parentheses.py) checks each port against an independent stack-based oracle, exhaustive parenthesis strings through length 14, seeded random strings, invalid values, and length boundaries.

## Upstream source

- [TheAlgorithms/C LeetCode 32](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/32.c)
