# Selection Sort Recursive

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged.

C ABI entry point: void selection_sort_recursive(int64_t *values, size_t length);

The algorithm recursively finds the minimum of the active suffix, swaps it into the first position, and recursively sorts the remaining suffix. Both recursive steps are retained. The workload caps length at 256 to bound recursion depth. The implementation uses portable scalar integer comparisons and swaps.

## Workload

[workload.json](workload.json) defines a deterministic modular-affine input values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001 for lengths 0, 1, 16, 64, 256. The sort runner generates input and a qsort reference before timing, restores input before each sample, and validates the complete output afterward.

Use [sort_runner.c](../../harness/sort_runner.c) and [run_sort.py](../../run_sort.py); each timed sample contains one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [c/s/selection_sort_recursive.c](../../../c/s/selection_sort_recursive.c) | Independent portable implementation; TheAlgorithms reference below |
| C3 | [c3/s/selection_sort_recursive.c3](../../../c3/s/selection_sort_recursive.c3) | Local port |
| C++ | [cpp/s/selection_sort_recursive.cpp](../../../cpp/s/selection_sort_recursive.cpp) | Independent portable implementation; TheAlgorithms reference below |
| Elisa | [elisa/s/selection_sort_recursive.elisa](../../../elisa/s/selection_sort_recursive.elisa) | Local port for the custom Elisa compiler |
| Nim | [nim/s/selection_sort_recursive.nim](../../../nim/s/selection_sort_recursive.nim) | Local port |
| Odin | [odin/s/selection_sort_recursive.odin](../../../odin/s/selection_sort_recursive.odin) | Local port |
| Rust | [rust/s/selection_sort_recursive.rs](../../../rust/s/selection_sort_recursive.rs) | Local port |
| V | [v/s/selection_sort_recursive.v](../../../v/s/selection_sort_recursive.v) | Local port |
| Zig | [zig/s/selection_sort_recursive.zig](../../../zig/s/selection_sort_recursive.zig) | Local port |

## TheAlgorithms references

The candidate appears in 4 source repositories. The checked implementations were inspected at the pinned commits recorded in the catalog:

- [C selection_sort_recursive.c](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/selection_sort_recursive.c)
- [C++ selection_sort_recursive.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/selection_sort_recursive.cpp)
- [Java SelectionSortRecursive.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/SelectionSortRecursive.java)
