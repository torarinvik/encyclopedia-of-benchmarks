# Detect Capital Usage

The pinned C LeetCode 520 file first counts uppercase letters. It accepts all-uppercase words, all-lowercase words, and title case. The nine ports implement that O(n) count method. The same source also contains a second implementation that rescans the word; it is benchmarked separately as [`detect_capital_usage_scan`](../detect_capital_usage_scan/README.md).

## Contract

- Input is an array of 0–1,024 ASCII letters (`A`–`Z` or `a`–`z`).
- Return 1 for all uppercase, all lowercase, or an uppercase first letter followed by lowercase letters. Return 0 for other capitalization patterns. Empty input returns 1.
- Return -1 for invalid characters or input longer than 1,024 bytes.
- This entry uses O(n) time and O(1) auxiliary storage, with integer comparisons only.

## Workload and verification

[`workload.json`](workload.json) covers valid and invalid capitalization patterns, invalid input, and maximum-length words. [`benchmarks/verify_detect_capital_usage.py`](../../verify_detect_capital_usage.py) checks both implementations in all nine languages against an independent ASCII-case oracle.

## Upstream source

- [TheAlgorithms/C LeetCode 520](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/520.c)
