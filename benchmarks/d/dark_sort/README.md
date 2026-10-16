# Dark sort

## Contract

Sort a mutable sequence of signed 64-bit integers in ascending order, in place. Inputs must contain keys in the inclusive range `[0, 128]`. Empty and one-element inputs are unchanged. This preserves the pinned Java implementation's max-indexed counting histogram, which assumes nonnegative keys; negative values are outside the source algorithm's valid domain.

The shared C ABI is `void dark_sort(int64_t *values, size_t length)`. Each port scans for the maximum, counts keys in a zero-initialized histogram indexed from zero, then writes each key back in ascending bucket order. The supported upper bound keeps histogram sizing and workload behavior portable.

## Workload and oracle

[`workload.json`](workload.json) generates values as `(index * 73) mod 129`, covering the full key range with duplicates for lengths `0`, `16`, `256`, and `1,024`. The generic sort runner creates and checks a sorted reference outside timing, restores the input for each sample, and validates the full sorted output. [`oracle.json`](oracle.json) records the expected behavior and benchmark cases.

Build with [`benchmarks/harness/sort_runner.c`](../../harness/sort_runner.c) and [`benchmarks/run_sort.py`](../../run_sort.py), using `-DBENCHMARK_FUNCTION=dark_sort`. Sort result records leave search-specific fields null.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/dark_sort.c`](../../../c/d/dark_sort.c) | Local port of the pinned Java implementation |
| C3 | [`c3/dark_sort.c3`](../../../c3/d/dark_sort.c3) | Local port |
| C++ | [`cpp/dark_sort.cpp`](../../../cpp/d/dark_sort.cpp) | Local port |
| Elisa | [`elisa/dark_sort.elisa`](../../../elisa/d/dark_sort.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/dark_sort.nim`](../../../nim/d/dark_sort.nim) | Local port |
| Odin | [`odin/dark_sort.odin`](../../../odin/d/dark_sort.odin) | Local port |
| Rust | [`rust/dark_sort.rs`](../../../rust/d/dark_sort.rs) | Local port |
| V | [`v/dark_sort.v`](../../../v/d/dark_sort.v) | Local port |
| Zig | [`zig/dark_sort.zig`](../../../zig/d/dark_sort.zig) | Local port |

## Pinned source

- [Java `DarkSort.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/sorts/DarkSort.java)
