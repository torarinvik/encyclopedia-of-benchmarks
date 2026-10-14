# Cocktail shaker sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is preserved because only strictly out-of-order adjacent values are swapped. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void cocktail_shaker_sort(int64_t *values, size_t length);
```

This name is commonly used for the same bidirectional adjacent-swap method as cocktail sort. Each round scans forward, then backward over the full sequence, stopping when neither pass swaps. Keeping this candidate name separate preserves the source inventory; both entries use the same workload for direct comparison.

## Workload

[`workload.json`](workload.json) matches the `cocktail_sort` workload: deterministic modular-affine signed inputs at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one cocktail-shaker-sort call, and verifies the complete output.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/c/cocktail_shaker_sort.c`](../../../c/c/cocktail_shaker_sort.c) | Local port |
| C3 | [`c3/c/cocktail_shaker_sort.c3`](../../../c3/c/cocktail_shaker_sort.c3) | Local port |
| C++ | [`cpp/c/cocktail_shaker_sort.cpp`](../../../cpp/c/cocktail_shaker_sort.cpp) | Local port |
| Elisa | [`elisa/c/cocktail_shaker_sort.elisa`](../../../elisa/c/cocktail_shaker_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/c/cocktail_shaker_sort.nim`](../../../nim/c/cocktail_shaker_sort.nim) | Local port |
| Odin | [`odin/c/cocktail_shaker_sort.odin`](../../../odin/c/cocktail_shaker_sort.odin) | Local port |
| Rust | [`rust/c/cocktail_shaker_sort.rs`](../../../rust/c/cocktail_shaker_sort.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/c/cocktail_shaker_sort.v`](../../../v/c/cocktail_shaker_sort.v) | Local port |
| Zig | [`zig/c/cocktail_shaker_sort.zig`](../../../zig/c/cocktail_shaker_sort.zig) | Local port |

The checked Rust version uses full-range forward and reverse passes and exits when a pass makes no swaps. Unlike the `cocktail_sort` entry, the local shaker-sort ports keep the full range active during every round.

## TheAlgorithms reference

The candidate appears in four source repositories. The direct Rust implementation was checked at the pinned commit in the catalog:

- [Rust `cocktail_shaker_sort.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/sorting/cocktail_shaker_sort.rs)
