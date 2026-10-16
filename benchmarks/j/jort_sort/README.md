# Jort sort

This benchmark follows the pinned AArch64 Assembly `jort_sort` implementation: it copies the input, insertion-sorts the copy, compares the result with the original, and reports whether they match.

## Contract

- Input is an array of 0 to 64 signed 64-bit integers. Every i64 value is accepted.
- Returns `1` when the copied array equals the original after the source routine's insertion pass, `0` otherwise, and `-1` for a null pointer with nonzero length or an invalid length. The source treats an empty array as sorted, so length zero returns `1`.
- The source's insertion loop skips the comparison against index 0. As a result, element 0 stays fixed while the suffix beginning at index 1 is sorted. This preserves the pinned behavior, including its false positive for `[2, 1]` and for any input whose suffix is sorted even when the full array is not.
- The source prints a message; the scalar result normalizes its `sorted`/`unsorted` outcome for the benchmark ABI.

## Source

Pinned source: [TheAlgorithms/AArch64_Assembly `jort_sort.s`](https://github.com/TheAlgorithms/AArch64_Assembly/blob/cb138a856a3af14d3d3dfcd2743d43841eec566f/sorters/jort_sort.s). The bounded domain prevents unbounded static storage while retaining the routine's copy, insertion-sort, and comparison behavior.

## Workload and running

[`workload.json`](workload.json) includes the pinned example, ordinary sorted and unsorted inputs, the index-0 false positives, empty input, duplicate and negative values, i64 extrema, and an invalid overlong input. The oracle is [`benchmarks/jort_sort_oracle.py`](../../jort_sort_oracle.py).

Build and verify a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm jort_sort --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithm jort_sort --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/jort_sort.c`](../../../c/j/jort_sort.c) |
| C3 | [`c3/j/jort_sort.c3`](../../../c3/j/jort_sort.c3) |
| C++ | [`cpp/j/jort_sort.cpp`](../../../cpp/j/jort_sort.cpp) |
| Elisa | [`elisa/j/jort_sort.elisa`](../../../elisa/j/jort_sort.elisa) |
| Nim | [`nim/j/jort_sort.nim`](../../../nim/j/jort_sort.nim) |
| Odin | [`odin/j/jort_sort.odin`](../../../odin/j/jort_sort.odin) |
| Rust | [`rust/j/jort_sort.rs`](../../../rust/j/jort_sort.rs) |
| V | [`v/j/jort_sort.v`](../../../v/j/jort_sort.v) |
| Zig | [`zig/j/jort_sort.zig`](../../../zig/j/jort_sort.zig) |
