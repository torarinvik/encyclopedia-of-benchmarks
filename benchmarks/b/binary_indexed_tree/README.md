# Binary indexed tree

This package ports the pinned C# `BinaryIndexedTree` point-update and prefix-sum operations. The workload starts with a zero-filled array and applies point additions. Inclusive range sums are computed from the source's prefix query as `GetSum(right) - GetSum(left - 1)`, with `GetSum(-1)` equal to zero.

Pinned source:

- C#: [TheAlgorithms/C-Sharp `BinaryIndexedTree.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Fenwick/BinaryIndexedTree.cs)

## Contract

Input is `[item_count, operation_count, opcode, first, second, ...]`, with one triple per operation. Opcode 0 adds `second` to item `first`; opcode 1 queries the inclusive range `[first, second]`. The array length must be a power of two from 2 through 256, operation count is 0 through 512, and update deltas are within ±1,000,000. Query endpoints and update indices must be valid for the array. Invalid input returns `-1`.

The C# source stores an `int[]` of length `n + 1` and its update loop checks `startFrom <= fenwickTree.Length`. For arbitrary non-power-of-two lengths this can advance to index `n + 1` and write past the array; length 1 also fails on an update. The power-of-two range above avoids that source defect while preserving the same point-update and prefix-sum operations. The bounded operation and delta counts keep source `int` tree cells within signed 32-bit range.

The signed 64-bit scalar result is a weighted checksum of inclusive range sums and final array values, matching the existing `fenwick_tree` workload's checksum formula. Output ordering of queries follows the input operation order. The workload includes empty traces, repeated updates, negative deltas, single-item ranges, maximum size and operation count, and malformed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_indexed_tree.c`](../../../c/b/binary_indexed_tree.c) |
| C3 | [`c3/b/binary_indexed_tree.c3`](../../../c3/b/binary_indexed_tree.c3) |
| C++ | [`cpp/b/binary_indexed_tree.cpp`](../../../cpp/b/binary_indexed_tree.cpp) |
| Elisa | [`elisa/b/binary_indexed_tree.elisa`](../../../elisa/b/binary_indexed_tree.elisa) |
| Nim | [`nim/b/binary_indexed_tree.nim`](../../../nim/b/binary_indexed_tree.nim) |
| Odin | [`odin/b/binary_indexed_tree.odin`](../../../odin/b/binary_indexed_tree.odin) |
| Rust | [`rust/b/binary_indexed_tree.rs`](../../../rust/b/binary_indexed_tree.rs) |
| V | [`v/b/binary_indexed_tree.v`](../../../v/b/binary_indexed_tree.v) |
| Zig | [`zig/b/binary_indexed_tree.zig`](../../../zig/b/binary_indexed_tree.zig) |
