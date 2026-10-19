# Cocktail sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Stability is preserved because only strictly out-of-order adjacent values are swapped. Empty and single-element inputs are unchanged.

The C ABI entry point is:

```c
void cocktail_sort(int64_t *values, size_t length);
```

Each round bubbles the largest remaining value to the right, then the smallest remaining value to the left. The bounds shrink after each pair of passes, and the function stops early when a pass makes no swaps. No auxiliary storage is needed.

## Workload

[`workload.json`](workload.json) uses deterministic modular-affine signed inputs at lengths `0`, `16`, `256`, and `1,024`. The runner prepares a sorted reference outside timing, restores input before each sample, times one cocktail-sort call, and verifies the complete output.

Use [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py). Search-only result fields remain null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/c/cocktail_sort.c`](../../../c/c/cocktail_sort.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/c/cocktail_sort.c3`](../../../c3/c/cocktail_sort.c3) | Local port |
| C++ | [`cpp/c/cocktail_sort.cpp`](../../../cpp/c/cocktail_sort.cpp) | Local port |
| Elisa | [`elisa/c/cocktail_sort.elisa`](../../../elisa/c/cocktail_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/c/cocktail_sort.nim`](../../../nim/c/cocktail_sort.nim) | Local port |
| Odin | [`odin/c/cocktail_sort.odin`](../../../odin/c/cocktail_sort.odin) | Local port |
| Rust | [`rust/c/cocktail_sort.rs`](../../../rust/c/cocktail_sort.rs) | Local port |
| V | [`v/c/cocktail_sort.v`](../../../v/c/cocktail_sort.v) | Local port |
| Zig | [`zig/c/cocktail_sort.zig`](../../../zig/c/cocktail_sort.zig) | Local port |

The inspected C source performs a forward adjacent-swap pass followed by a backward pass, reducing the active range and stopping when no swap occurs. It assumes the caller supplies the array size; the local ABI represents that size with `size_t` and handles empty input explicitly.

The `cocktail_shaker_sort` name describes the same bidirectional adjacent-swap algorithm. Some sources rescan the full range while others shrink the bounds; these pass-bound differences remain within this benchmark and do not have a separate suite entry.

## TheAlgorithms reference

The candidate appears in seven source repositories, including an AArch64 assembly implementation. The portable C source was checked at the pinned commit in the catalog:

- [C `cocktail_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/cocktail_sort.c)
