# Univalued binary tree

Return whether every node in the tree has the same value. The recursive check compares each child with its parent, then checks both subtrees. An empty tree is univalued.

## Contract

- Input is a caller-owned indexed table of at most 1,023 `[signed 64-bit value, left_child_index, right_child_index]` triplets. Child index `-1` means absent.
- A nonempty input is one valid rooted binary tree. The root can have any table index. An empty tree uses zero nodes and root index `-1`.
- Return `1` when every node has the same value, `0` when any child differs from its parent, and `-1` for invalid roots, child indexes, or tables over 1,023 nodes.
- The implementation uses recursive traversal and caller-owned storage. The node bound limits recursion depth to 1,023.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton trees, equal values, mismatches at different depths and sides, signed 64-bit extremes, nonzero roots, invalid indexes, and a 1,023-node path. [`benchmarks/verify_univalued_binary_tree.py`](../../verify_univalued_binary_tree.py) checks all nine ports against an independent iterative tree oracle, every ordered tree shape through seven nodes, deterministic random trees, and the published workload.

The benchmark follows [TheAlgorithms C LeetCode source `965.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/965.c), which recursively compares each child value with its parent.

Build with the shared `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
