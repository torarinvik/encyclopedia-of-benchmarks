# Segment tree update

## Contract

This benchmark extracts construction, point updates, and inclusive range-sum queries from the pinned C# `SegmentTreeUpdate` and its base `SegmentTree`. Input is `[n, initial_values..., operation_count, operation triples...]`, where `n` and `operation_count` are 1..64. Each operation is `[type, arg1, arg2]`: type 0 queries inclusive range `[arg1,arg2]`; type 1 replaces `initial_values[arg1]` with `arg2`. Queries require `0 <= arg1 <= arg2 < n`; updates require `0 <= arg1 < n`.

Initial and update values are in `[-1000000,1000000]`, keeping every tree sum within signed 32-bit range. The packed length must be exactly `n + 2 + 3 * operation_count`, and at least one query is required. Invalid input returns `-1`.

For valid input, the result is the low 63 bits of standard FNV-1a-64 over signed 64-bit little-endian words `[query_count, query_sum_0, ...]` in query order. The hash starts at `14695981039346656037` and uses prime `1099511628211`.

The source does not validate indices; this benchmark wrapper rejects malformed operation streams, out-of-range indices, and null input before accessing the tree.

## Workload

[`workload.json`](workload.json) covers inclusive boundaries, negative values, non-power-of-two padding, point updates followed by queries, repeated updates, zero and negative sums, maximum dimensions, and malformed operations and lengths.

## TheAlgorithms reference

- C# [`SegmentTreeUpdate.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTreeUpdate.cs) replaces one leaf and recursively propagates parent sums.
- C# [`SegmentTree.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/SegmentTrees/SegmentTree.cs) pads to the next power of two, builds parent sums, and performs inclusive recursive queries.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/segment_tree_update.c](../../../c/s/segment_tree_update.c) |
| C3 | [c3/s/segment_tree_update.c3](../../../c3/s/segment_tree_update.c3) |
| C++ | [cpp/s/segment_tree_update.cpp](../../../cpp/s/segment_tree_update.cpp) |
| Elisa | [elisa/s/segment_tree_update.elisa](../../../elisa/s/segment_tree_update.elisa) |
| Nim | [nim/s/segment_tree_update.nim](../../../nim/s/segment_tree_update.nim) |
| Odin | [odin/s/segment_tree_update.odin](../../../odin/s/segment_tree_update.odin) |
| Rust | [rust/s/segment_tree_update.rs](../../../rust/s/segment_tree_update.rs) |
| V | [v/s/segment_tree_update.v](../../../v/s/segment_tree_update.v) |
| Zig | [zig/s/segment_tree_update.zig](../../../zig/s/segment_tree_update.zig) |
