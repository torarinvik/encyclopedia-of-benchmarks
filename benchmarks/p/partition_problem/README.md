# Partition Problem

Decide whether a nonempty multiset of nonnegative integers can be split into two subsets with equal sums. Return `1` when a split exists, `0` when it does not, and `-1` for invalid input.

## Contract

- The input is the item array itself, with 1 to 16 values.
- Each value is in `0..256`, and the total is at most 1,024.
- Duplicate values represent distinct indexed items. Zero is valid; a nonempty all-zero input is partitionable.
- The result is a boolean encoded as an integer.

The implementations use one-dimensional subset-sum reachability, updating reachable totals downward for each item so an item is used at most once. This preserves the pinned sources' bottom-up dynamic-programming approach while using fixed bounds that are safe across the target languages.

[`workload.json`](workload.json) includes the upstream example, even and odd totals, zeros, duplicate items, boundary values, and invalid inputs. [`benchmarks/verify_partition_problem.py`](../../verify_partition_problem.py) checks every implementation against an exhaustive subset-mask oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/partition_problem.c`](../../../c/p/partition_problem.c) |
| C3 | [`c3/p/partition_problem.c3`](../../../c3/p/partition_problem.c3) |
| C++ | [`cpp/p/partition_problem.cpp`](../../../cpp/p/partition_problem.cpp) |
| Elisa | [`elisa/p/partition_problem.elisa`](../../../elisa/p/partition_problem.elisa) |
| Nim | [`nim/p/partition_problem.nim`](../../../nim/p/partition_problem.nim) |
| Odin | [`odin/p/partition_problem.odin`](../../../odin/p/partition_problem.odin) |
| Rust | [`rust/p/partition_problem.rs`](../../../rust/p/partition_problem.rs) |
| V | [`v/p/partition_problem.v`](../../../v/p/partition_problem.v) |
| Zig | [`zig/p/partition_problem.zig`](../../../zig/p/partition_problem.zig) |

## Upstream sources

- [TheAlgorithms/C-Plus-Plus `partition_problem.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/partition_problem.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `partition_problem.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/partition_problem.cpp)
- [TheAlgorithms/Java `PartitionProblem.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/PartitionProblem.java)

Each source repository's pinned revision is licensed under MIT: [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/LICENSE), [C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/LICENSE), and [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/LICENSE).
