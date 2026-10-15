# Trim a Binary Search Tree

Recursively remove BST nodes outside an inclusive value range. A node below the range is replaced by its right subtree; a node above the range is replaced by its left subtree; an in-range node keeps its value and recursively trimmed children.

## Contract

- Input is an indexed BST with node rows `[value, left_index, right_index]`, a root index, and inclusive `low`/`high` bounds.
- Trees have at most 100 nodes, distinct values in 1 through 10,000, and valid strict BST ordering. An empty tree uses root index -1.
- The caller provides output storage of at least `1 + 3 * input_node_count` signed 64-bit values.
- Return the number of serialized output values. The output is `[new_root_index, value, left_index, right_index, ...]`; child indexes refer to compact preorder node-table rows. An empty trimmed tree is serialized as `[-1]`.
- Return -1 for invalid tree data or bounds, and -2 when the output pointer or capacity is insufficient.

## Workload and verification

[`workload.json`](workload.json) covers roots pruned on either side, retained trees, empty output, a maximum-size chain, malformed BSTs, and insufficient output capacity. [`benchmarks/verify_trim_bst.py`](../../verify_trim_bst.py) checks all nine ports against an independent recursive trimming oracle across generated strict BSTs, ranges, invalid structures, and each workload case.

## Reviewed source

The pinned C [LeetCode 669 implementation](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/669.c) skips left or right subtrees when the root lies outside the requested range, then trims both children of retained nodes.

## Implementations

All nine ports use the dedicated `tree_trim` ABI family. It passes the indexed tree, root, range, and caller-owned output buffer, and checks the serialized tree result.
