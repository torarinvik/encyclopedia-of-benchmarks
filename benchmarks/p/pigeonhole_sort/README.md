# Pigeonhole sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Every key must be in the inclusive range `[-128, 128]`. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void pigeonhole_sort(int64_t *values, int64_t *scratch, size_t length);
```

The implementation maps each key to one of 257 pigeonholes, counts occurrences, then writes each key back in ascending order. The scratch array needs 257 signed 64-bit counters; the benchmark runner reserves this storage before timing. Complexity is `O(n + 257)` for this fixed key range.

## Workload

[`workload.json`](workload.json) uses the same deterministic modular-affine signed inputs as counting sort, including duplicates, at lengths `0`, `16`, `256`, and `1,024`. This lets the two bounded-key sorts be compared on identical inputs. The runner prepares a sorted reference outside timing, restores input before each sample, times one pigeonhole-sort call, and verifies the full output.

Build the runner with `-DBENCHMARK_WITH_SCRATCH -DBENCHMARK_SCRATCH_EXTRA=257`. Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/p/pigeonhole_sort.c`](../../../c/p/pigeonhole_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/p/pigeonhole_sort.c3`](../../../c3/p/pigeonhole_sort.c3) | Local port |
| C++ | [`cpp/p/pigeonhole_sort.cpp`](../../../cpp/p/pigeonhole_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/p/pigeonhole_sort.elisa`](../../../elisa/p/pigeonhole_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/p/pigeonhole_sort.nim`](../../../nim/p/pigeonhole_sort.nim) | Local port |
| Odin | [`odin/p/pigeonhole_sort.odin`](../../../odin/p/pigeonhole_sort.odin) | Local port |
| Rust | [`rust/p/pigeonhole_sort.rs`](../../../rust/p/pigeonhole_sort.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/p/pigeonhole_sort.v`](../../../v/p/pigeonhole_sort.v) | Local port |
| Zig | [`zig/p/pigeonhole_sort.zig`](../../../zig/p/pigeonhole_sort.zig) | Local port |

The inspected C implementation finds the input range and allocates its holes dynamically. C++ returns a fixed-size array and uses a zero sentinel while emitting keys; Rust stores both hole keys and occurrence counts in vectors. The local contract uses a bounded signed domain so every port can share one reusable counter array and process duplicate keys consistently.

## TheAlgorithms references

The candidate appears in eight source repositories. These local source implementations were checked at the pinned commits in the catalog:

- [C `pigeonhole_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/pigeonhole_sort.c)
- [C++ `pigeonhole_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/pigeonhole_sort.cpp)
- [Rust `pigeonhole_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/pigeonhole_sort.rs)
