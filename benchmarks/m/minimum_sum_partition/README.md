# Minimum Sum Partition

Split a multiset of nonnegative integers into two subsets so the difference between their sums is as small as possible. Return that minimum difference.

## Contract

- The input is the item array itself. It may contain 0 through 64 values, each between 0 and 4,096, with a total sum no greater than 4,096.
- Empty input returns 0. Duplicate values represent distinct indexed items; zero is valid.
- Negative values, values or totals above the bound, and arrays longer than 64 values return `-1`.
- The parser accepts 65 values so the one-over-limit array reaches the function. A positive-length null pointer also returns `-1`.

The pinned Java implementation uses a one-dimensional subset-sum table up to half the total, updating sums downward for each item and returning `total - 2 * closestPartitionSum`. The Python `minimum_partition` source uses the same recurrence in a two-dimensional table and returns the same value on this nonnegative domain. The bounded total keeps the Java `int` arithmetic safe and limits either table to 2,049 subset sums. The independent oracle tracks reachable sums in a set rather than using the ports' boolean tables.

[`workload.json`](workload.json) covers the source examples, empty and zero inputs, balanced and unbalanced partitions, the sum and length limits, and malformed values. The oracle is [`benchmarks/minimum_sum_partition_oracle.py`](../../minimum_sum_partition_oracle.py).

## Reviewed source

[TheAlgorithms/Java `MinimumSumPartition.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/MinimumSumPartition.java)

[TheAlgorithms/Python `minimum_partition.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/minimum_partition.py)

Both pinned source revisions are licensed under MIT: [Java LICENSE](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE) and [Python LICENSE](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/LICENSE).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm minimum_sum_partition --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm minimum_sum_partition
python3 benchmarks/verify_i64_array_scalar.py --algorithm minimum_sum_partition
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/minimum_sum_partition.c`](../../../c/m/minimum_sum_partition.c) |
| C3 | [`c3/m/minimum_sum_partition.c3`](../../../c3/m/minimum_sum_partition.c3) |
| C++ | [`cpp/m/minimum_sum_partition.cpp`](../../../cpp/m/minimum_sum_partition.cpp) |
| Elisa | [`elisa/m/minimum_sum_partition.elisa`](../../../elisa/m/minimum_sum_partition.elisa) |
| Nim | [`nim/m/minimum_sum_partition.nim`](../../../nim/m/minimum_sum_partition.nim) |
| Odin | [`odin/m/minimum_sum_partition.odin`](../../../odin/m/minimum_sum_partition.odin) |
| Rust | [`rust/m/minimum_sum_partition.rs`](../../../rust/m/minimum_sum_partition.rs) |
| V | [`v/m/minimum_sum_partition.v`](../../../v/m/minimum_sum_partition.v) |
| Zig | [`zig/m/minimum_sum_partition.zig`](../../../zig/m/minimum_sum_partition.zig) |
