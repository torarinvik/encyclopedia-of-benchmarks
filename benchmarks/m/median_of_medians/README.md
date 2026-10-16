# Median of medians

Select the value at a requested sorted rank using deterministic median-of-medians pivots.

## Contract

The `i64_array_scalar` input is `[n, k, values...]`, where `n` is 1–25, `k` is a zero-based rank in `[0,n)`, and values are distinct integers in `[0, 2^31-1]`. Valid calls return the value at rank `k`; malformed shapes, out-of-range values, or duplicates return `-1`.

The ports use corrected groups of at most five, sort each group, take its middle value, then recurse on the medians to choose a pivot. Selection partitions around that pivot until it reaches the requested zero-based rank.

## Source semantics

The pinned [TheAlgorithms Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/median_of_medians.py) exposes a `median_of_medians` pivot helper and a `quick_select` routine whose rank parameter is one-based. The source's group boundary check can use `arr[i:]` for a group of five and therefore consume more than five remaining values. The benchmark uses corrected five-element groups and a documented zero-based selection rank; input sizes are bounded to keep the contract small.

The oracle is [`median_of_medians_oracle.py`](../../median_of_medians_oracle.py), which compares against sorted order.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/median_of_medians.c](../../../c/m/median_of_medians.c) |
| C3 | [c3/m/median_of_medians.c3](../../../c3/m/median_of_medians.c3) |
| C++ | [cpp/m/median_of_medians.cpp](../../../cpp/m/median_of_medians.cpp) |
| Elisa | [elisa/m/median_of_medians.elisa](../../../elisa/m/median_of_medians.elisa) |
| Nim | [nim/m/median_of_medians.nim](../../../nim/m/median_of_medians.nim) |
| Odin | [odin/m/median_of_medians.odin](../../../odin/m/median_of_medians.odin) |
| Rust | [rust/m/median_of_medians.rs](../../../rust/m/median_of_medians.rs) |
| V | [v/m/median_of_medians.v](../../../v/m/median_of_medians.v) |
| Zig | [zig/m/median_of_medians.zig](../../../zig/m/median_of_medians.zig) |

The package uses the `i64_array_scalar` benchmark ABI.
