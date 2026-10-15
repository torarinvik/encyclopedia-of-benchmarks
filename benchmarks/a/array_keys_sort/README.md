# Multi-key array sort

This benchmark follows PHP `ArrayKeysSort::sort` on its array-of-arrays path. The comparator checks selected fields in the supplied priority order and sorts ascending or descending. The source stringifies each value and lowercases it by default; this benchmark uses bounded integer values, for which PHP's numeric-string comparison has the same order as integer comparison. Case conversion therefore has no effect on this domain. Rows with equal selected-key tuples are excluded so their relative order does not depend on the PHP runtime's sort stability.

## Contract

The `i64_array_bytes_output` ABI packs `[row_count, key_count, order, key_0, ..., rows...]`. There are 1..64 rows with exactly four integer fields each. The key list contains 1..4 distinct field numbers from 1 through 4, in comparator priority order. `order` is 1 for ascending or 0 for descending. Field values are in `[-1000, 1000]`, and every row has a unique tuple across the selected keys. The packed length must be exactly `3 + key_count + 4*row_count`.

The output returns all four fields for every sorted row as little-endian signed 64-bit integers. Success returns `32*row_count` bytes. Malformed input returns `-1`; a null or undersized output buffer returns `-2`. The workload covers key priority, direction, one and four selected keys, negative values, maximum row count, and invalid input.

## Pinned source and ports

- PHP [`ArrayKeysSort.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Sorting/ArrayKeysSort.php)

| Language | Source |
| --- | --- |
| C | [`c/a/array_keys_sort.c`](../../../c/a/array_keys_sort.c) |
| C3 | [`c3/a/array_keys_sort.c3`](../../../c3/a/array_keys_sort.c3) |
| C++ | [`cpp/a/array_keys_sort.cpp`](../../../cpp/a/array_keys_sort.cpp) |
| Elisa | [`elisa/a/array_keys_sort.elisa`](../../../elisa/a/array_keys_sort.elisa) |
| Nim | [`nim/a/array_keys_sort.nim`](../../../nim/a/array_keys_sort.nim) |
| Odin | [`odin/a/array_keys_sort.odin`](../../../odin/a/array_keys_sort.odin) |
| Rust | [`rust/a/array_keys_sort.rs`](../../../rust/a/array_keys_sort.rs) |
| V | [`v/a/array_keys_sort.v`](../../../v/a/array_keys_sort.v) |
| Zig | [`zig/a/array_keys_sort.zig`](../../../zig/a/array_keys_sort.zig) |
