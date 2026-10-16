# Inorder successor in a binary search tree

Build a binary search tree by inserting keys in input order, then return the inorder successor of a requested key. The successor is the smallest tree key greater than the requested key.

## Contract

- The `i64_array_scalar` input is `[n, target, key_0, ..., key_(n-1)]`.
- `n` is 0 through 64. The target and all inserted keys are positive signed 32-bit integers; inserted keys must be distinct.
- Return the successor key. Return `0` when the target is absent or has no successor, matching the source's null-pointer result.
- Invalid shape, duplicate keys, or out-of-domain values return `-1`.
- The source inserts keys in the given order, searches for the target, then finds the minimum of its right subtree or the nearest ancestor reached from the left.

Positive keys make the null result `0` distinct from every valid successor; `-1` is reserved for invalid input.

## Workload and source

[`workload.json`](workload.json) covers both successor cases, source examples, absent and maximum keys, an empty tree, the node limit, and malformed inputs. The independent sorted-order oracle is [`inorder_successor_of_bst_oracle.py`](../../inorder_successor_of_bst_oracle.py).

- [TheAlgorithms/C-Plus-Plus `operations_on_datastructures/inorder_successor_of_bst.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/inorder_successor_of_bst.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `operations_on_datastructures/inorder_successor_of_bst.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/operations_on_datastructures/inorder_successor_of_bst.cpp)

Both pinned copies use the same insertion, lookup, right-subtree minimum, and ancestor-walk logic. The benchmark limits inputs to distinct keys so lookup identifies one node unambiguously.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/i/inorder_successor_of_bst.c`](../../../c/i/inorder_successor_of_bst.c) |
| C3 | [`c3/i/inorder_successor_of_bst.c3`](../../../c3/i/inorder_successor_of_bst.c3) |
| C++ | [`cpp/i/inorder_successor_of_bst.cpp`](../../../cpp/i/inorder_successor_of_bst.cpp) |
| Elisa | [`elisa/i/inorder_successor_of_bst.elisa`](../../../elisa/i/inorder_successor_of_bst.elisa) |
| Nim | [`nim/i/inorder_successor_of_bst.nim`](../../../nim/i/inorder_successor_of_bst.nim) |
| Odin | [`odin/i/inorder_successor_of_bst.odin`](../../../odin/i/inorder_successor_of_bst.odin) |
| Rust | [`rust/i/inorder_successor_of_bst.rs`](../../../rust/i/inorder_successor_of_bst.rs) |
| V | [`v/i/inorder_successor_of_bst.v`](../../../v/i/inorder_successor_of_bst.v) |
| Zig | [`zig/i/inorder_successor_of_bst.zig`](../../../zig/i/inorder_successor_of_bst.zig) |
