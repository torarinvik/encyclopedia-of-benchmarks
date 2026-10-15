# Iterative quicksort

This variant uses Lomuto partitioning with the final value in each range as the pivot. It stores pending half-open ranges in an explicit stack instead of making recursive calls. The implementation processes the smaller side immediately and records the larger side, which bounds the stack to logarithmic space while preserving the iterative strategy.

## Contract

- Sort a mutable array of signed 64-bit integers in ascending order.
- Empty and one-element arrays are unchanged.
- Duplicate values and the full signed 64-bit range are supported.
- The sort is not stable.
- The final value of each range is the pivot; worst-case running time remains quadratic.

## Workload and verification

The workload uses deterministic modular-affine input at lengths 0, 16, 256, and 1,024. `verify_quick_sort_iterative.py` checks all short-array relative-order and duplicate patterns, signed 64-bit boundaries, seeded random arrays, and the published workload through the shared sort ABI.

## Reviewed TheAlgorithms source

[C++ `quick_sort_iterative.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/quick_sort_iterative.cpp) partitions around the last value and stores pending integer-index ranges on an explicit stack. The nine local ports preserve those choices and omit the source file's driver and self-test code.
