# Intro Sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. C ABI entry point: void intro_sort(int64_t *values, size_t length).

The sort uses a middle-element quicksort partition, switches to insertion sort for ranges of at most 16 values, and falls back to heapsort when its recursion budget is exhausted. The shared budget is 2 floor(log2(n)), calculated with integer shifts so all ports make the same portable choice without floating-point logarithms. Implementations use portable scalar integer operations and do not require CPU-specific instructions.

## Workload

[workload.json](workload.json) defines deterministic input values by the formula values[index] = ((index * 48271) mod 2000003) - 1000001 for lengths 0, 16, 256, 1024. The sort runner generates input and a qsort reference before timing, restores the original input before each sample, and validates the complete output afterward.

Use [sort_runner.c](../../harness/sort_runner.c) and [run_sort.py](../../run_sort.py); each timed sample contains one sort call.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [c/i/intro_sort.c](../../../c/i/intro_sort.c) | Local port |
| C3 | [c3/i/intro_sort.c3](../../../c3/i/intro_sort.c3) | Local port |
| C++ | [cpp/i/intro_sort.cpp](../../../cpp/i/intro_sort.cpp) | Local port |
| Elisa | [elisa/i/intro_sort.elisa](../../../elisa/i/intro_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [nim/i/intro_sort.nim](../../../nim/i/intro_sort.nim) | Local port |
| Odin | [odin/i/intro_sort.odin](../../../odin/i/intro_sort.odin) | Local port |
| Rust | [rust/i/intro_sort.rs](../../../rust/i/intro_sort.rs) | Independent portable implementation; TheAlgorithms reference below |
| V | [v/i/intro_sort.v](../../../v/i/intro_sort.v) | Local port |
| Zig | [zig/i/intro_sort.zig](../../../zig/i/intro_sort.zig) | Local port |

## TheAlgorithms references

The candidate appears in 4 source repositories. These reference implementations were inspected at the pinned commits recorded in the catalog:

- [Rust intro_sort.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/intro_sort.rs)
- [Python intro_sort.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/intro_sort.py)
