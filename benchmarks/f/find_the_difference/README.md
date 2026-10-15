# Find the Difference

The pinned C LeetCode implementation sums the character codes in both strings and returns the target sum minus the source sum. The nine portable ports preserve that O(n) method.

## Contract

- Input is packed as `[source_length, target_length, source_bytes..., target_bytes...]` in an array of signed 64-bit values.
- The source is 0–4,096 lowercase ASCII letters. The target is a permutation of the source with one additional lowercase ASCII letter.
- Return the ASCII code of the added character. Return `-1` for malformed packed lengths, invalid bytes, or string lengths outside the contract.
- The maximum packed input has 8,195 values; all sums fit safely in signed 64-bit arithmetic.

## Workload and verification

[`workload.json`](workload.json) covers empty and repeated-letter sources, reordered targets, a maximum-length source, and malformed packed inputs. [`benchmarks/verify_find_the_difference.py`](../../verify_find_the_difference.py) checks the sum method against an independent multiset oracle using exhaustive short strings and seeded random valid pairs.

## Upstream source

- [TheAlgorithms/C LeetCode 389](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/389.c)
