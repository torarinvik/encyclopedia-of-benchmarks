# Binary tree local ordering

Check the parent-child ordering used by the pinned Python `Node.is_sorted` property. The source recursively checks that every left child is no greater than its parent and every right child is no less than its parent. It does not enforce ancestor-wide bounds, so a value in the left subtree can exceed the root and still pass if every direct edge is ordered.

## Contract

- ABI: `i64_array_scalar`. The input is a heap-indexed array of tree slots: root at index 0, left child at `2*i+1`, and right child at `2*i+2`.
- The input contains 1 through 255 slots. Each present node value is signed int32. The marker `-2147483649` denotes an absent child.
- Every present non-root node must have a present parent. A missing root, orphan node, invalid value, or more than 255 slots returns `-1`.
- Return `1` when each direct left edge satisfies `child <= parent` and each direct right edge satisfies `child >= parent`; otherwise return `0`.
- Duplicate values are allowed. This benchmark uses integer values as an exact bounded subset of the Python source's numeric data.

The local edge rule intentionally matches the source's recursive comparisons; this is not the usual global binary-search-tree validity check. In particular, `[5, 3, 7, -2147483649, 6]` passes: the left child's right child is locally ordered relative to `3`, even though it is greater than the root `5`.

[`workload.json`](workload.json) covers leaf nodes, duplicates, left and right violations, missing children, the source's local-only ancestor-bound behavior, and malformed encodings.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_tree_is_sorted_local.c`](../../../c/b/binary_tree_is_sorted_local.c) |
| C3 | [`c3/b/binary_tree_is_sorted_local.c3`](../../../c3/b/binary_tree_is_sorted_local.c3) |
| C++ | [`cpp/b/binary_tree_is_sorted_local.cpp`](../../../cpp/b/binary_tree_is_sorted_local.cpp) |
| Elisa | [`elisa/b/binary_tree_is_sorted_local.elisa`](../../../elisa/b/binary_tree_is_sorted_local.elisa) |
| Nim | [`nim/b/binary_tree_is_sorted_local.nim`](../../../nim/b/binary_tree_is_sorted_local.nim) |
| Odin | [`odin/b/binary_tree_is_sorted_local.odin`](../../../odin/b/binary_tree_is_sorted_local.odin) |
| Rust | [`rust/b/binary_tree_is_sorted_local.rs`](../../../rust/b/binary_tree_is_sorted_local.rs) |
| V | [`v/b/binary_tree_is_sorted_local.v`](../../../v/b/binary_tree_is_sorted_local.v) |
| Zig | [`zig/b/binary_tree_is_sorted_local.zig`](../../../zig/b/binary_tree_is_sorted_local.zig) |

## Pinned source

- [Python `data_structures/binary_tree/is_sorted.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/is_sorted.py)
