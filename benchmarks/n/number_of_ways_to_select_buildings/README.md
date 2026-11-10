# Number of Ways to Select Buildings

Count the length-three subsequences `010` and `101` in a binary string. Characters need not be adjacent; their positions must be increasing. This is the linear counter used by the pinned C LeetCode 2222 implementation.

## Contract

- Pass the string as an array of ASCII values: `'0'` is 48 and `'1'` is 49.
- Inputs may contain 0 through 4096 characters. Other values or longer inputs return `-1`.
- The input is read only. The result is the number of alternating subsequences of length three; an empty string returns 0.
- Each implementation makes one pass, tracking single characters and ordered pairs. The incoming character first completes triples, then extends pairs, then increments its own count. The same pass validates ASCII input by accumulating the bits that differ from 48. Time is O(n) and auxiliary space is O(1).

## Workload and verification

[`workload.json`](workload.json) covers empty, short, uniform, mixed, and alternating strings, plus alternating and seeded random strings at the 4,096-character limit. [`benchmarks/verify_number_of_ways_to_select_buildings.py`](../../verify_number_of_ways_to_select_buildings.py) checks nine implementations by default and supports Mojo with `--languages mojo`. It compares results against an independent center-counting oracle, including exhaustive strings through length 12, deterministic random strings, the maximum input length, and malformed inputs.

## Upstream source

- [TheAlgorithms/C LeetCode 2222](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2222.c)
