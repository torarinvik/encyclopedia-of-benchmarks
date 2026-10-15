# Binary Tree Inorder Traversal

Write each node value in left-node-right order into caller-owned output storage and return the number of values written. The tree uses indexed records `[value, left_child_index, right_child_index]`; `-1` denotes a missing child.

## Contract

- Inputs contain 0 through 100 nodes. An empty tree uses root index `-1` and returns zero values.
- A nonempty input is one valid rooted binary tree with every node reachable exactly once. The root may be at any table index.
- Node values are in `[-100, 100]`, matching LeetCode 94. Output elements are represented as signed 64-bit integers for the shared ABI.
- The caller provides an output buffer with capacity at least the node count. Too-small buffers and invalid roots return `-1` without writing output.
- The source allocates 256 `int` elements, while the official problem limits trees to 100 nodes. This benchmark preserves the official node/value bounds and writes into caller-owned storage.

## Algorithm and verification

The pinned C source recursively visits the left child, writes the current value, and then visits the right child. The nine ports preserve that recursive inorder traversal over general binary trees; no BST ordering is required. The verifier compares them with an independent iterative inorder oracle over all ordered shapes through seven nodes, seeded random trees, maximum-size balanced and skewed trees, and output/root boundary cases.

The source is [TheAlgorithms C LeetCode `94.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/94.c); the problem statement is [LeetCode 94: Binary Tree Inorder Traversal](https://leetcode.com/problems/binary-tree-inorder-traversal/).

Build with the `tree_value_output` ABI family and record with `benchmarks/run_tree_value_output.py`. Verify all ports with `python3 benchmarks/verify_binary_tree_inorder_traversal.py`.
