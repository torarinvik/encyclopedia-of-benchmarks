# Bead sort

## Contract

Sort a mutable sequence of nonnegative signed 64-bit integers in ascending order, in place. Input values must be in `[0, 63]`; the bounded domain is part of this algorithm's workload contract. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void bead_sort(int64_t *values, int64_t *scratch, size_t length);
```

A value `v` is represented by beads on `v` posts. The implementation stores each post's bead height in a 64-counter scratch array, applies gravity by reconstructing rows from the heights, and writes the sorted row counts back. This is equivalent to the bead-fall formulation without allocating an `n × max(value)` bitmap inside the timed call. It uses `O(64)` scratch and `O(n × 64)` work for the fixed domain. The scratch allocation is prepared outside timing.

## Workload

[`workload.json`](workload.json) generates values in `[0, 63]` with a deterministic modular sequence at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one bead-sort call, and verifies the full output.

Build the runner with `-DBENCHMARK_WITH_SCRATCH -DBENCHMARK_SCRATCH_EXTRA=64`. Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/b/bead_sort.c`](../../../c/b/bead_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/b/bead_sort.c3`](../../../c3/b/bead_sort.c3) | Local port |
| C++ | [`cpp/b/bead_sort.cpp`](../../../cpp/b/bead_sort.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/b/bead_sort.elisa`](../../../elisa/b/bead_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/b/bead_sort.nim`](../../../nim/b/bead_sort.nim) | Local port |
| Odin | [`odin/b/bead_sort.odin`](../../../odin/b/bead_sort.odin) | Local port |
| Rust | [`rust/b/bead_sort.rs`](../../../rust/b/bead_sort.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/b/bead_sort.v`](../../../v/b/bead_sort.v) | Local port |
| Zig | [`zig/b/bead_sort.zig`](../../../zig/b/bead_sort.zig) | Local port |

The inspected C and C++ examples allocate an explicit bead matrix for nonnegative integers. Rust also rejects negative values and constructs a matrix of nested vectors. AArch64 assembly appears as another filename candidate but is architecture-specific, so it is excluded from portable implementations. The local contract keeps the natural nonnegative domain and bounds values to 63 so every language uses a small reusable counter buffer and the same workload.

## TheAlgorithms references

The candidate appears in nine source repositories. These local source implementations were checked at the pinned commits in the catalog:

- [C `bead_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/bead_sort.c)
- [C++ `bead_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/bead_sort.cpp)
- [Rust `bead_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/bead_sort.rs)
