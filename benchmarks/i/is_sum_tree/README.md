# Is sum tree

## Contract

Return whether every internal node's value equals the sum of all values in its left and right descendant subtrees. A leaf is always considered valid. This follows the pinned Python `BinaryTree.is_sum_tree` property and `Node.is_sum_node` implementation.

The `tree_scalar` ABI represents each node as `[value, left_index, right_index]`; `-1` denotes a missing child. The tree must contain 1..400 node records, and the root index may be any in-range index. Node values are in `[-1,000,000,000, 1,000,000,000]`. The root-reachable portion must be an acyclic tree with no shared child; table entries outside it are ignored. Results are `1` for a sum tree and `0` otherwise. Invalid inputs return `-9,000,000,000,000,000,000`.

The source computes each child's full subtree sum by inorder traversal, then recursively checks both child subtrees. The ports preserve that repeated-sum approach and evaluate both child predicates even if the current node value fails. Its worst-case work is quadratic on a highly skewed tree; the 400-node cap bounds this work and keeps recursion depth safely bounded. Summing at most 400 bounded node values fits signed 64-bit arithmetic.

This predicate differs from `binary_tree_node_sum`, which returns one total, and from `path_sum` / `binary_tree_path_sum`, which inspect root-to-leaf or downward paths. It is also distinct from `binary_tree_maximum_path_sum`, which maximizes a path across parent-child edges.

## Workload and implementations

[`workload.json`](workload.json) covers the pinned valid and invalid tree examples, leaf behavior, negative values, arbitrary roots, and malformed structure. The `tree_scalar` runner needs an `is_sum_tree` oracle case before these workload entries can use the standard recording path; runner and aggregate files are left unchanged here.

| Language | Source |
| --- | --- |
| C | [`c/i/is_sum_tree.c`](../../../c/i/is_sum_tree.c) |
| C3 | [`c3/i/is_sum_tree.c3`](../../../c3/i/is_sum_tree.c3) |
| C++ | [`cpp/i/is_sum_tree.cpp`](../../../cpp/i/is_sum_tree.cpp) |
| Elisa | [`elisa/i/is_sum_tree.elisa`](../../../elisa/i/is_sum_tree.elisa) |
| Nim | [`nim/i/is_sum_tree.nim`](../../../nim/i/is_sum_tree.nim) |
| Odin | [`odin/i/is_sum_tree.odin`](../../../odin/i/is_sum_tree.odin) |
| Rust | [`rust/i/is_sum_tree.rs`](../../../rust/i/is_sum_tree.rs) |
| V | [`v/i/is_sum_tree.v`](../../../v/i/is_sum_tree.v) |
| Zig | [`zig/i/is_sum_tree.zig`](../../../zig/i/is_sum_tree.zig) |

## Pinned source

- [Python `is_sum_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/is_sum_tree.py)
