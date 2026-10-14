# Exchange Sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged.

C ABI entry point: void exchange_sort(int64_t *values, size_t length);

The algorithm scans each suffix and swaps every later value that is smaller than the current value into the current position. This preserves the inspected Rust implementation pattern. Exchange sort is not stable. The implementation uses portable scalar integer comparisons and swaps.

## Workload

[workload.json](workload.json) defines a deterministic modular-affine input values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001 for lengths 0, 16, 256, 1024. The sort runner generates input and a qsort reference before timing, restores input before each sample, and validates the complete output afterward.

Use [sort_runner.c](../../harness/sort_runner.c) and [run_sort.py](../../run_sort.py); each timed sample contains one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [c/e/exchange_sort.c](../../../c/e/exchange_sort.c) | Local port |
| C3 | [c3/e/exchange_sort.c3](../../../c3/e/exchange_sort.c3) | Local port |
| C++ | [cpp/e/exchange_sort.cpp](../../../cpp/e/exchange_sort.cpp) | Local port |
| Elisa | [elisa/e/exchange_sort.elisa](../../../elisa/e/exchange_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [nim/e/exchange_sort.nim](../../../nim/e/exchange_sort.nim) | Local port |
| Odin | [odin/e/exchange_sort.odin](../../../odin/e/exchange_sort.odin) | Local port |
| Rust | [rust/e/exchange_sort.rs](../../../rust/e/exchange_sort.rs) | Independent portable implementation; TheAlgorithms reference below |
| V | [v/e/exchange_sort.v](../../../v/e/exchange_sort.v) | Local port |
| Zig | [zig/e/exchange_sort.zig](../../../zig/e/exchange_sort.zig) | Local port |

## TheAlgorithms references

The candidate appears in 4 source repositories. The checked implementations were inspected at the pinned commits recorded in the catalog:

- [Rust exchange_sort.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/exchange_sort.rs)
