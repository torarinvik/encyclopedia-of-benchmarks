# Random-pivot quicksort

Random-pivot quicksort selects a pivot index from each active range, moves that value to the end, and uses Lomuto partitioning to place values strictly smaller than the pivot on the left. Equal values stay on the right for that partition. An explicit range stack keeps the implementation iterative; it processes the smaller side immediately and records the larger side.

## Contract

- Sort a mutable array of signed 64-bit integers in ascending order.
- Empty and one-element arrays are unchanged.
- Duplicate values and the full signed 64-bit range are supported.
- The sort is not stable; duplicate-heavy inputs can still produce quadratic work with two-way Lomuto partitioning.
- Pivot choices come from the same fixed-seed Park–Miller stream in each language, so runs are reproducible across platforms.

## Workload and verification

The workload uses deterministic modular-affine input at lengths 0, 16, 256, and 1,024. `verify_random_pivot_quick_sort.py` checks exhaustive short-array order and duplicate patterns, signed 64-bit boundaries, seeded random arrays, and every published workload length through the shared sort ABI.

## Reviewed TheAlgorithms sources

- [C++ `random_pivot_quick_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/random_pivot_quick_sort.cpp)
- [C `random_quick_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/random_quick_sort.c)
- [Java `RandomizedQuickSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/randomized/RandomizedQuickSort.java)
- [C# `RandomPivotQuickSorter.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/RandomPivotQuickSorter.cs)

The upstream sources seed randomness differently or depend on the host runtime's random generator. These ports use a small explicit generator so the benchmark exercises randomized pivot selection with repeatable cross-platform inputs.
