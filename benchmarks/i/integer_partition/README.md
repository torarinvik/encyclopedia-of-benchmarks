# Integer Partition Count

This benchmark ports the pinned Python and Rust `integer_partition` routines. For a positive integer `n`, they return the number `p(n)` of ways to write `n` as a sum of positive integers when reordering summands does not create a new partition.

## Contract

- The scalar input is `n`, in the range `1..=300`.
- The result is the exact signed 64-bit partition count. In particular, `p(1) = 1`, `p(5) = 7`, and `p(300) = 9,253,082,936,723,602`.
- Inputs outside the range return `INT64_MIN`. Both pinned sources require a positive input and fail for zero or negative values; the sentinel gives those cases a defined benchmark result.
- The bound keeps the exact result within signed 64-bit range and bounds the source's quadratic table to at most 301 rows by 300 columns.

Both sources use the same two-dimensional recurrence. They initialize `memo[i][0] = 1`, then for each row `n` and column `k` from `1` through `m-1`, add `memo[n][k-1]` and, when `n > k`, add `memo[n-k-1][k]`. The answer is `memo[m][m-1]`. The ports preserve this recurrence and iteration order.

This counts unordered integer partitions of one integer. It differs from `subset_sum_count`, which counts choices from a supplied indexed array, and from two-set partition tasks such as `minimum_partition` and `partition_problem`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/integer_partition.c`](../../../c/i/integer_partition.c) |
| C3 | [`c3/i/integer_partition.c3`](../../../c3/i/integer_partition.c3) |
| C++ | [`cpp/i/integer_partition.cpp`](../../../cpp/i/integer_partition.cpp) |
| Elisa | [`elisa/i/integer_partition.elisa`](../../../elisa/i/integer_partition.elisa) |
| Nim | [`nim/i/integer_partition.nim`](../../../nim/i/integer_partition.nim) |
| Odin | [`odin/i/integer_partition.odin`](../../../odin/i/integer_partition.odin) |
| Rust | [`rust/i/integer_partition.rs`](../../../rust/i/integer_partition.rs) |
| V | [`v/i/integer_partition.v`](../../../v/i/integer_partition.v) |
| Zig | [`zig/i/integer_partition.zig`](../../../zig/i/integer_partition.zig) |

## Workload and recording

[`workload.json`](workload.json) covers representative partition counts through the maximum supported input and the invalid-input sentinel. All nine ports use the shared `scalar` ABI family. The source-backed oracle in [`benchmarks/run_scalar.py`](../../run_scalar.py) checks each expected partition count.

Build with the `scalar` ABI family and record the workload with `benchmarks/run_scalar.py`.

## Pinned sources

- [TheAlgorithms/Python `integer_partition.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/integer_partition.py)
- [TheAlgorithms/Rust `integer_partition.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/integer_partition.rs)
