# Valid Palindrome

Check whether the input reads the same in both directions after ignoring non-alphanumeric ASCII characters and ASCII letter case. Two pointers scan inward, skipping punctuation before each comparison.

## Contract

- Input is an array of signed 64-bit integers representing ASCII code points, with length 0 through 4,096.
- Values from 0 through 127 are valid. Zero and other non-alphanumeric controls are ignored like punctuation.
- Return 1 when the remaining letters and digits form a palindrome, or 0 otherwise. Empty and punctuation-only inputs return 1.
- Out-of-range values and oversized arrays return -1.

The benchmark uses an explicit length, so it can represent embedded NUL values consistently across languages; this also avoids locale-dependent character classification and case conversion.

## Workload and verification

[`workload.json`](workload.json) covers the standard phrase, mismatches, digits, case folding, punctuation, controls, and the maximum supported length. [`verify_valid_palindrome.py`](../../verify_valid_palindrome.py) checks all nine ports against an independent filter-and-reverse oracle on exhaustive short arrays, boundaries, seeded random inputs, and every workload case.

## Reviewed TheAlgorithms source

The pinned C [LeetCode 125 implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/125.c) uses inward-moving indices, skips non-alphanumeric characters, and folds ASCII case before comparing. The shared contract makes character classification explicitly ASCII and uses a length-prefixed input array.

## Implementations

All nine portable implementations use the shared i64-array/scalar ABI.
