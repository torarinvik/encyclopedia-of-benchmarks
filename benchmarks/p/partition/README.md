# Partition problem

## Contract

Input is `[count, values...]`, with 0–16 nonnegative values and each value at most 1,000. Return `1` if the values can be divided into two subsets with equal sum, otherwise `0`. A malformed array, negative value, or value above the bound returns `-1`.

The benchmark follows the pinned recursive search: if the current subset sum equals half the total, succeed; if the input is exhausted or the target has passed half, fail; otherwise recurse by including the current value first, then excluding it. Nonnegative values make the source's `target > half` pruning correct. The empty list and an all-zero list succeed because the initial target equals half.

## Source review

The pinned TypeScript `canPartition` recomputes the array sum in its recursive calls, rejects odd totals, checks the target before the end condition, and explores include before exclude. Its pruning assumes nonnegative values; the benchmark makes that domain explicit. The port keeps the recursion but computes the total once at the entry point.

Pinned source: [JavaScript `Partition.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Recursive/Partition.js).

## Workload and implementations

[`workload.json`](workload.json) covers empty and zero-only inputs, possible and impossible partitions, odd totals, and invalid inputs. The [runtime oracle](../../partition_oracle.py) matches the recursive contract.

| Language | Port |
|---|---|
| C | [`c/p/partition.c`](../../../c/p/partition.c) |
| C3 | [`c3/p/partition.c3`](../../../c3/p/partition.c3) |
| C++ | [`cpp/p/partition.cpp`](../../../cpp/p/partition.cpp) |
| Elisa | [`elisa/p/partition.elisa`](../../../elisa/p/partition.elisa) |
| Nim | [`nim/p/partition.nim`](../../../nim/p/partition.nim) |
| Odin | [`odin/p/partition.odin`](../../../odin/p/partition.odin) |
| Rust | [`rust/p/partition.rs`](../../../rust/p/partition.rs) |
| V | [`v/p/partition.v`](../../../v/p/partition.v) |
| Zig | [`zig/p/partition.zig`](../../../zig/p/partition.zig) |
