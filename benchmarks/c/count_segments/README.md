# Count Segments in a String

The pinned C LeetCode implementation scans left to right and increments the result when a non-space byte follows a space (or the start of the string). The portable ports keep that one-pass transition count and use an explicit input length.

## Contract

- Input is an array of 0–4,096 signed 64-bit values representing nonzero ASCII bytes (1–127).
- ASCII space (32) is the only delimiter. Tabs, newlines, and punctuation are ordinary segment bytes.
- Return the number of nonempty segments. Empty input and strings containing only spaces return 0.
- Return `-1` for a value outside 1–127 or an input longer than 4,096 values.
- The algorithm uses O(n) time and O(1) auxiliary storage, with portable integer operations.

## Workload and verification

[`workload.json`](workload.json) covers space runs, leading and trailing spaces, non-space ASCII characters, invalid byte values, and maximum-length inputs. [`benchmarks/verify_count_segments.py`](../../verify_count_segments.py) checks each language against a split-based oracle using exhaustive short space/letter strings and seeded random byte sequences.

## Upstream source

- [TheAlgorithms/C LeetCode 434](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/434.c)
