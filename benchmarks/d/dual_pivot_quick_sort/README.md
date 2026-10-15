# Dual-pivot quicksort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. For each active half-open range, order the first and final values as two pivots, then partition values into a lower region, a middle region, and an upper region. Stability is not promised.

The C ABI entry point is:

```c
void dual_pivot_quick_sort(int64_t *values, size_t length);
```

The lower region contains values below the first pivot; the middle region contains values from the first pivot up to but excluding the second; the upper region contains values at least the second pivot. The ports recurse into the smaller regions and iterate over the largest, bounding stack depth. Worst-case time remains `O(n²)` and each partition takes `O(n)` work.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine signed inputs at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one sort call, and checks the complete output.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only fields to null.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/dual_pivot_quick_sort.c`](../../../c/d/dual_pivot_quick_sort.c) |
| C3 | [`c3/d/dual_pivot_quick_sort.c3`](../../../c3/d/dual_pivot_quick_sort.c3) |
| C++ | [`cpp/d/dual_pivot_quick_sort.cpp`](../../../cpp/d/dual_pivot_quick_sort.cpp) |
| Elisa | [`elisa/d/dual_pivot_quick_sort.elisa`](../../../elisa/d/dual_pivot_quick_sort.elisa) |
| Nim | [`nim/d/dual_pivot_quick_sort.nim`](../../../nim/d/dual_pivot_quick_sort.nim) |
| Odin | [`odin/d/dual_pivot_quick_sort.odin`](../../../odin/d/dual_pivot_quick_sort.odin) |
| Rust | [`rust/d/dual_pivot_quick_sort.rs`](../../../rust/d/dual_pivot_quick_sort.rs) |
| V | [`v/d/dual_pivot_quick_sort.v`](../../../v/d/dual_pivot_quick_sort.v) |
| Zig | [`zig/d/dual_pivot_quick_sort.zig`](../../../zig/d/dual_pivot_quick_sort.zig) |

## TheAlgorithms reference

- [Java `DualPivotQuickSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/DualPivotQuickSort.java)
