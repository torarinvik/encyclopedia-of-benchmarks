# Recursive Bubble Sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. C ABI entry point: void recursive_bubble_sort(int64_t *values, size_t length).

Each recursive call makes one adjacent-swap pass over the active prefix, which moves its maximum value to the end, then recurses on the shorter prefix. The pass is performed even when no swaps occur. The workload caps recursion depth at 256. Implementations use portable scalar comparisons and swaps.

## Workload

[workload.json](workload.json) defines deterministic modular-affine input values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001 for lengths 0, 1, 16, 64, 256. The runner restores input before each sample and checks the complete sorted output after timing.

Use [sort_runner.c](../../harness/sort_runner.c) and [run_sort.py](../../run_sort.py); each timed sample contains one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [c/r/recursive_bubble_sort.c](../../../c/r/recursive_bubble_sort.c) | Local port |
| C3 | [c3/r/recursive_bubble_sort.c3](../../../c3/r/recursive_bubble_sort.c3) | Local port |
| C++ | [cpp/r/recursive_bubble_sort.cpp](../../../cpp/r/recursive_bubble_sort.cpp) | Independent portable implementation; TheAlgorithms source below |
| Elisa | [elisa/r/recursive_bubble_sort.elisa](../../../elisa/r/recursive_bubble_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [nim/r/recursive_bubble_sort.nim](../../../nim/r/recursive_bubble_sort.nim) | Local port |
| Odin | [odin/r/recursive_bubble_sort.odin](../../../odin/r/recursive_bubble_sort.odin) | Local port |
| Rust | [rust/r/recursive_bubble_sort.rs](../../../rust/r/recursive_bubble_sort.rs) | Local port |
| V | [v/r/recursive_bubble_sort.v](../../../v/r/recursive_bubble_sort.v) | Local port |
| Zig | [zig/r/recursive_bubble_sort.zig](../../../zig/r/recursive_bubble_sort.zig) | Local port |

## TheAlgorithms references

This filename candidate appears in 3 source repositories. The inspected references were checked at the pinned commits recorded in the catalog:

- [C++ recursive_bubble_sort.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/recursive_bubble_sort.cpp)
- [Fortran recursive_bubble_sort.f90](https://github.com/TheAlgorithms/Fortran/blob/c91199703b78bd2181051b01bd5269740e41e121/modules/sorts/recursive_bubble_sort.f90)
