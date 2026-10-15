# Three-way quicksort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Empty and single-element inputs are unchanged. Each active half-open range uses its final value as the pivot and partitions into values less than, equal to, and greater than the pivot. Stability is not promised.

The C ABI entry point is:

```c
void quick_sort_3(int64_t *values, size_t length);
```

The implementations recurse into the smaller outer partition and iterate over the larger one, bounding call-stack depth while preserving the three-way partition. Worst-case time remains `O(n²)` for unfavorable pivot order; partitioning takes `O(n)`. Auxiliary storage is `O(1)` apart from the bounded recursive stack.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine signed inputs at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one sort call, and checks the complete output.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Sort result records set search-only fields to null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/q/quick_sort_3.c`](../../../c/q/quick_sort_3.c) | Local portable port |
| C3 | [`c3/q/quick_sort_3.c3`](../../../c3/q/quick_sort_3.c3) | Local port |
| C++ | [`cpp/q/quick_sort_3.cpp`](../../../cpp/q/quick_sort_3.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/q/quick_sort_3.elisa`](../../../elisa/q/quick_sort_3.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/q/quick_sort_3.nim`](../../../nim/q/quick_sort_3.nim) | Local port |
| Odin | [`odin/q/quick_sort_3.odin`](../../../odin/q/quick_sort_3.odin) | Local port |
| Rust | [`rust/q/quick_sort_3.rs`](../../../rust/q/quick_sort_3.rs) | Local port |
| V | [`v/q/quick_sort_3.v`](../../../v/q/quick_sort_3.v) | Local port |
| Zig | [`zig/q/quick_sort_3.zig`](../../../zig/q/quick_sort_3.zig) | Local port |

The two pinned C++ files are identical and use Dutch-national-flag partitioning around the final value. The Rust `quick_sort_3_ways` candidate uses the same three partitions with a randomized pivot; it is recorded as an alias because pivot choice changes the partition sequence, not the three-way quicksort family represented here.

## TheAlgorithms references

- [C++ `quick_sort_3.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/quick_sort_3.cpp)
- [Identical additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/quick_sort_3.cpp)
- [Rust `quick_sort_3_ways.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/quick_sort_3_ways.rs)
