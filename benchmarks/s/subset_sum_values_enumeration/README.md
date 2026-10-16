# Positive Subset Sum Value Enumeration

This package ports the pinned R `find_all_subsets` routine. It enumerates matching value lists, preserving the source's include-first traversal and early return as soon as the current sum equals the target. Different input positions remain distinct results even when their value lists are identical.

## Contract

- The `i64_array_bytes_output` input is `[target, item0, item1, ...]`; a target with no items is valid.
- The target is in `[0, 256]`; there are at most 11 items, each in `[1, 64]`. Items are strictly positive so the source's sum pruning and early-return behavior apply.
- Output is a sequence of records. Each record is `[subset_length, item0, item1, ...]`, with all fields encoded as signed little-endian 64-bit integers. Records appear in include-first traversal order. There is no outer count prefix; the output byte length delimits the record sequence.
- When target is zero, the source immediately returns one empty subset, even when items are present. A positive target with no matching subset returns zero bytes.
- Invalid length or values return `-1`. Insufficient output capacity returns `-2` without writing output. Otherwise the function returns the output byte length.
- At most 11 items require at most 2,048 records; the conservative output bound is 2,048 × (one length field + 11 values) × 8 = 196,608 bytes.

[`workload.json`](workload.json) covers target-zero behavior, empty items, exact and absent targets, repeated value lists from duplicate input positions, include-first ordering, the item-count bound, invalid values, and insufficient capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/subset_sum_values_enumeration.c`](../../../c/s/subset_sum_values_enumeration.c) |
| C3 | [`c3/s/subset_sum_values_enumeration.c3`](../../../c3/s/subset_sum_values_enumeration.c3) |
| C++ | [`cpp/s/subset_sum_values_enumeration.cpp`](../../../cpp/s/subset_sum_values_enumeration.cpp) |
| Elisa | [`elisa/s/subset_sum_values_enumeration.elisa`](../../../elisa/s/subset_sum_values_enumeration.elisa) |
| Nim | [`nim/s/subset_sum_values_enumeration.nim`](../../../nim/s/subset_sum_values_enumeration.nim) |
| Odin | [`odin/s/subset_sum_values_enumeration.odin`](../../../odin/s/subset_sum_values_enumeration.odin) |
| Rust | [`rust/s/subset_sum_values_enumeration.rs`](../../../rust/s/subset_sum_values_enumeration.rs) |
| V | [`v/s/subset_sum_values_enumeration.v`](../../../v/s/subset_sum_values_enumeration.v) |
| Zig | [`zig/s/subset_sum_values_enumeration.zig`](../../../zig/s/subset_sum_values_enumeration.zig) |

## Upstream source

- [TheAlgorithms/R `find_all_subsets` in `subset_sum.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/subset_sum.r)
