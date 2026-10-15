# Balanced binary tree

Return whether the tree is height-balanced: every node's left and right subtree heights differ by at most one. The implementation preserves the source's recursive height calculation followed by recursive checks of the child subtrees. An empty tree is balanced.

## Contract

- Input is a caller-owned indexed table of at most 1,023 `[value, left_child_index, right_child_index]` triplets. Values are ignored. Child index `-1` means absent.
- A nonempty input is one valid rooted binary tree. The root can have any table index. An empty tree uses zero nodes and root index `-1`.
- Return `1` when the tree is height-balanced and `0` otherwise. Invalid roots, child indexes, and tables over 1,023 nodes return `-1`.
- The recursive height and balance traversals use no heap allocation. The node bound limits recursion depth to 1,023.

## Workload and verification

[`workload.json`](workload.json) covers empty, single-node, balanced, root-unbalanced, internally unbalanced, nonzero-root, signed-value, invalid-index, and 1,023-node chain cases. [`benchmarks/verify_balanced_binary_tree.py`](../../verify_balanced_binary_tree.py) checks all nine ports against an independent iterative postorder oracle, every ordered tree shape through seven nodes, deterministic random trees, and the published workload.

The benchmark follows [TheAlgorithms C LeetCode source `110.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/110.c). That source computes subtree heights and then checks each subtree recursively.

Build with the shared `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
