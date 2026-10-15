# Rotate Array

The pinned C LeetCode 189 source rotates right by repeatedly moving the final element to the front and shifting the remaining values one place. The nine ports preserve that repeated-shift algorithm and write the resulting signed 32-bit values to a separate output buffer.

## Contract

- The input is `[rotation_count, values...]`; `rotation_count` is from 0 to 1,024 and the array has 0 to 1,024 signed 32-bit values.
- Return the rotated array as little-endian signed 32-bit values and return its element count. Empty arrays return 0.
- Return `-1` for invalid lengths, rotation counts, or values. Return `-2` when the output buffer is too small.
- Input values are left unchanged. The benchmark uses the source's repeated one-place shift, which takes O(n × k) time and O(n) local storage.

Run `python3 benchmarks/verify_rotate_array.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against exhaustive short arrays, seeded random cases, boundaries, malformed inputs, and the published workload.

## Inspected upstream source

- [C — LeetCode `189.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/189.c)
