# Search in a BST

Find the node whose value equals the target by following the BST search path. The packed input is `[node count, root index, target value, node triples...]`, where each node is `[value, left child index, right child index]` and `-1` marks a missing child. Return the table index of the matching node, or `-1` when it is absent. That index identifies the root of the subtree the source C function returns.

## Contract

- The tree has 1 through 5,000 nodes. The root may have any table index.
- Node values are unique and in `[1, 10,000,000]`; targets use the same range.
- The input is a valid rooted binary search tree with every node reachable exactly once.
- Malformed headers, roots, or target values return `-1`. Tree links follow the valid-tree input contract.
- The node and value limits match LeetCode 700 and fit within the shared array-scalar input limit.

## Algorithm and verification

The pinned C source compares the current node with the target, returns the current node when equal, and recursively chooses only the left or right subtree. The ports preserve that branch-by-branch search. The table index is the portable representation of the returned subtree pointer. Verification uses an independent full-tree oracle over all ordered shapes through six nodes, seeded random BSTs, the official examples, and 5,000-node balanced and skewed trees.

The source is [TheAlgorithms C LeetCode `700.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/700.c); the problem statement is [LeetCode 700: Search in a Binary Search Tree](https://leetcode.com/problems/search-in-a-binary-search-tree/).

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`. Verify all ports with `python3 benchmarks/verify_search_in_bst.py`.
