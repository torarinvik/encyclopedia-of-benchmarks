# Sort Array By Parity

Partition an integer array so that every even value appears before every odd value. The pinned C implementation writes even values forward and odd values backward from the output end. This fixes a repeatable output order while satisfying the problem's parity partition.

## Contract

- Accept 0 to 5,000 integers from 0 through 5,000. Empty input is an extension to the published problem domain.
- Preserve the order of even values and reverse the order of odd values, matching the pinned C implementation. Emit signed 32-bit little-endian values and return the output length.
- Return -1 for an invalid length or value. Return -2 if the caller's output buffer is too small.
- The algorithm takes O(n) time and writes into the caller's output buffer.

## Workload and verification

[workload.json](workload.json) covers the examples, empty and single-element inputs, even-only and odd-only arrays, duplicates, value bounds, invalid values, and the maximum length. [benchmarks/verify_sort_array_by_parity.py](../../verify_sort_array_by_parity.py) checks the nine ports against the pinned placement order using exhaustive short arrays and seeded larger arrays.

Run the command: python3 benchmarks/verify_sort_array_by_parity.py --elisa-compiler /absolute/path/to/elisac.

## Reviewed source

- [TheAlgorithms/C LeetCode 905 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/905.c) and the [LeetCode problem statement](https://leetcode.com/problems/sort-array-by-parity/)
