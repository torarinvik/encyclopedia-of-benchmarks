# Jewels and Stones

The pinned C LeetCode implementation builds a character-frequency lookup from the jewel string and then sums the lookup values for the stones. The nine portable ports preserve this O(J + S) table-based method.

## Contract

- Input is packed as `[jewel_count, stone_count, jewel_bytes..., stone_bytes...]` in signed 64-bit values.
- Jewels are unique nonzero ASCII bytes (1–127), up to 127 values. Stones use the same byte range and may repeat, up to 4,096 values.
- Return the number of stones whose byte is in the jewel set. Return `-1` for malformed lengths, invalid bytes, or duplicate jewel bytes.
- A 128-entry integer table provides O(1) membership checks; the algorithm uses O(J + S) time.

## Workload and verification

[`workload.json`](workload.json) covers empty inputs, repeated stones, invalid packed data, and maximum-length inputs. [`benchmarks/verify_jewels_and_stones.py`](../../verify_jewels_and_stones.py) checks all nine ports against a set-membership oracle over exhaustive short jewel/stone strings and seeded random inputs.

## Upstream source

- [TheAlgorithms/C LeetCode 771](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/771.c)
