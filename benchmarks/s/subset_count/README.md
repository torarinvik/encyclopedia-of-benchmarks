# Subset count

This benchmark ports the space-optimized getCountSO method from the pinned Java SubsetCount source.

## Contract

The i64_array_scalar input is [n, target, values...]. It requires 1 <= n <= 30, 0 <= target <= 64, every value in 0..64, and exactly n + 2 signed 64-bit integers. The parser accepts up to 33 values so a trailing value can be rejected explicitly.

The output is the count produced by the source recurrence. Invalid shape or values return -1. The count fits a signed 32-bit integer under these bounds.

The source initializes prev[0] to 1 and sets prev[values[0]] to 1 when values[0] <= target. For each later value it creates a fresh table, sets cur[0] to 1, and for each t from 1 through target stores prev[t] plus prev[t - value] when value <= t. It does not update t=0. This source behavior means target 0 always returns 1; a zero at the first position does not multiply positive-target counts, while later zeros double positive-target counts.

## Pinned source and workload

This package follows [TheAlgorithms/Java SubsetCount.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/SubsetCount.java) at commit e43ec3897e48f23843972d02cd05a5bb1b6864a2. Only getCountSO is in scope.

See the [workload](workload.json) and [oracle](../../subset_count_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [subset_count.c](../../../c/s/subset_count.c) |
| C3 | [subset_count.c3](../../../c3/s/subset_count.c3) |
| C++ | [subset_count.cpp](../../../cpp/s/subset_count.cpp) |
| Elisa | [subset_count.elisa](../../../elisa/s/subset_count.elisa) |
| Nim | [subset_count.nim](../../../nim/s/subset_count.nim) |
| Odin | [subset_count.odin](../../../odin/s/subset_count.odin) |
| Rust | [subset_count.rs](../../../rust/s/subset_count.rs) |
| V | [subset_count.v](../../../v/s/subset_count.v) |
| Zig | [subset_count.zig](../../../zig/s/subset_count.zig) |
