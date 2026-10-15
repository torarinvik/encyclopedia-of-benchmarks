# Detect Capital Usage by Repeated Scan

The pinned C LeetCode 520 source includes an alternative implementation that checks each uppercase byte after the first by rescanning the entire word to determine whether every character is uppercase. The nine ports preserve this O(n²) worst-case procedure so its performance can be compared with the O(n) uppercase-count method in [`detect_capital_usage`](../detect_capital_usage/README.md).

## Contract

- Input is an array of 0–1,024 ASCII letters (`A`–`Z` or `a`–`z`).
- Return 1 for all uppercase, all lowercase, or an uppercase first letter followed by lowercase letters. Return 0 for other capitalization patterns. Empty input returns 1.
- Return -1 for invalid characters or input longer than 1,024 bytes.
- This entry uses O(n²) time in the all-uppercase case and O(1) auxiliary storage.

## Workload and verification

[`workload.json`](workload.json) uses the same input cases as the uppercase-count benchmark, including a maximum-length all-uppercase word that exposes repeated scans. [`benchmarks/verify_detect_capital_usage.py`](../../verify_detect_capital_usage.py) checks both implementations in all nine languages against an independent ASCII-case oracle.

## Upstream source

- [TheAlgorithms/C LeetCode 520](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/520.c)
