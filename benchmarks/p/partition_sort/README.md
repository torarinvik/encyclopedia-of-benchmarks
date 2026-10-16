# Partition sort

Sort signed integer arrays in ascending order using quicksort with Hoare's partition scheme. The first element in each range is the pivot. The source routine mutates its array and writes the sorted values to stdout only in its demo; the benchmark ports sort in place without demo output.

## Contract

- The `sort_call` ABI receives a mutable array and its length. Empty and one-element arrays are unchanged.
- For nontrivial ranges, partition with two scans around the first-element pivot: advance the left scan to a value greater than or equal to the pivot, retreat the right scan to a value less than or equal to it, swap while the scans have not met, and return the right scan as the split.
- Recursively sort the inclusive subranges `[low, split]` and `[split + 1, high]`. The sort is not stable.
- Values use signed 32-bit inputs, matching the upstream C `int` domain. The ABI transports them as signed 64-bit values.

## Workload

[`workload.json`](workload.json) uses the shared deterministic modular-affine sort input at lengths 0, 16, 256, and 1,024. The sort runner restores each array before timing and compares the complete result against an ascending reference.

Verify with `python3 benchmarks/verify_partition_sort.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Pinned source

- TheAlgorithms/C [`partition_sort.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/sorting/partition_sort.c)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/partition_sort.c`](../../../c/p/partition_sort.c) |
| C3 | [`c3/p/partition_sort.c3`](../../../c3/p/partition_sort.c3) |
| C++ | [`cpp/p/partition_sort.cpp`](../../../cpp/p/partition_sort.cpp) |
| Elisa | [`elisa/p/partition_sort.elisa`](../../../elisa/p/partition_sort.elisa) |
| Nim | [`nim/p/partition_sort.nim`](../../../nim/p/partition_sort.nim) |
| Odin | [`odin/p/partition_sort.odin`](../../../odin/p/partition_sort.odin) |
| Rust | [`rust/p/partition_sort.rs`](../../../rust/p/partition_sort.rs) |
| V | [`v/p/partition_sort.v`](../../../v/p/partition_sort.v) |
| Zig | [`zig/p/partition_sort.zig`](../../../zig/p/partition_sort.zig) |
