# Tim sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. The sort is stable. Empty and single-element inputs are unchanged.

C ABI entry point: void tim_sort(int64_t *values, int64_t *scratch, size_t length);

The caller-provided scratch array must hold at least length signed 64-bit values. The benchmark runner allocates and reuses it before timing. The local implementation forms runs of at most 32 values with insertion sort, then merges adjacent runs in doubling widths. Merge chooses from the left run on equal keys to preserve stability.

## Workload

[workload.json](workload.json) defines the shared deterministic modular-affine input values[index] = ((index * 48,271) mod 2,000,003) - 1,000,001 for lengths 0, 16, 256, and 1,024. Input creation, scratch allocation, reset, reference sorting, and output validation stay outside each timed call.

Build the sort runner with -DBENCHMARK_WITH_SCRATCH. Use [sort_runner.c](../../harness/sort_runner.c) and [run_sort.py](../../run_sort.py).

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [c/t/tim_sort.c](../../../c/t/tim_sort.c) | Independent portable implementation based on the C++ source |
| C3 | [c3/t/tim_sort.c3](../../../c3/t/tim_sort.c3) | Local port |
| C++ | [cpp/t/tim_sort.cpp](../../../cpp/t/tim_sort.cpp) | Independent portable implementation; TheAlgorithms C++ source below |
| Elisa | [elisa/t/tim_sort.elisa](../../../elisa/t/tim_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [nim/t/tim_sort.nim](../../../nim/t/tim_sort.nim) | Local port |
| Odin | [odin/t/tim_sort.odin](../../../odin/t/tim_sort.odin) | Local port |
| Rust | [rust/t/tim_sort.rs](../../../rust/t/tim_sort.rs) | Local port; the upstream Rust variant is also reviewed |
| V | [v/t/tim_sort.v](../../../v/t/tim_sort.v) | Local port |
| Zig | [zig/t/tim_sort.zig](../../../zig/t/tim_sort.zig) | Local port |

## TheAlgorithms references

Tim sort appears in eight source repositories. The inspected C++ implementation inserts each 32-value run and merges runs bottom-up, allocating temporary arrays inside each merge. The inspected Rust implementation also uses insertion-sorted runs and merging, but computes its run length differently. The shared contract follows the explicit 32-value-run C++ structure and moves scratch allocation outside timing.

- [C++ tim_sort.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/tim_sort.cpp)
- [Rust tim_sort.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/tim_sort.rs)
