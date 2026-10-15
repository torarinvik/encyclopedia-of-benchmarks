# Palindromic Substrings

This benchmark counts every contiguous substring that reads the same forwards and backwards. Occurrences are counted separately, so identical text at different positions contributes more than once.

## Contract

- Input is an array of signed 64-bit integer code points representing ASCII lowercase English letters.
- Valid input length is 1 through 1000. Empty input, an out-of-range length, or a non-lowercase value returns -1.
- The result is the number of palindromic substring occurrences. The maximum result is 500,500.
- Ports expand around each odd and even center, taking O(n²) time and O(1) auxiliary space.

## Inspected upstream source

- [TheAlgorithms/C LeetCode 647](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/647.c)

The pinned source counts odd- and even-length palindromes by expanding from centers. The cross-language ports retain that counting behavior and use iterative expansion.

## Workload and verification

The workload covers single-character, odd, even, repeated-character, maximum-length, and invalid inputs. The verifier checks each implementation against an independent interval dynamic-programming oracle, including exhaustive short strings and deterministic boundary cases.

Run with:

    python3 benchmarks/verify_palindromic_substrings.py --elisa-compiler /absolute/path/to/elisac

Build and record with the i64_array_scalar ABI family. Source ports are in p/ in all nine language directories.
