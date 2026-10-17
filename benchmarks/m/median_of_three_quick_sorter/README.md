# Median-of-three quicksort

This benchmark specializes the pinned C# median-of-three quicksort to signed 64-bit integers with natural signed ordering.

## Contract

- Sort a mutable array of signed 64-bit integers in ascending order, in place. The supported length is 0 through 256. Empty and single-element arrays are unchanged; duplicate values are retained. Stability is not promised.
- For each active inclusive range `[left, right]` with more than one element, select the median of the values at `left`, `left + floor((right-left)/2)`, and `right`, then partition with the inherited Hoare quicksort. A consistent total signed ordering is required.
- The exported function is `void median_of_three_quick_sorter(int64_t *values, size_t length)`, following the `sort_call` comparison model. The shared runner supplies a nonnull storage pointer for the empty case and checks the complete array against a `qsort` reference prepared outside timing.

## Workload

[`workload.json`](workload.json) uses a deterministic modular-affine sequence at lengths 0, 16, and 256:

```text
values[index] = ((index * 48271) mod 127) - 63
```

The maximum-length case contains repeated keys, exercising equal-value partition behavior. The runner restores the original input before each timed call and verifies the full sorted output afterward. No algorithm-specific oracle is needed because the shared sort runner compares against its independent `qsort` result.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py).

## Pinned source

- [C# `MedianOfThreeQuickSorter<T>`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/MedianOfThreeQuickSorter.cs) selects the median pivot.
- Its [base `QuickSorter<T>`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/QuickSorter.cs) uses Hoare partitioning and stops when `left >= right`.

Both files are pinned at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`.
