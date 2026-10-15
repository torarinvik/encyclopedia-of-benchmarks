# Kth Smallest in a BST

Return the value at the one-based `k`th position in an inorder traversal of a binary search tree. The input uses indexed node records `[value, left_child_index, right_child_index]`; `-1` denotes a missing child.

## Contract

- Inputs contain 1 through 1,023 nodes. The root may be at any table index.
- The tree is a valid rooted BST with unique values and every node reachable exactly once.
- Node values are in `[0, 10,000]`; `k` is in `[1, node_count]`.
- Invalid root or rank inputs return `-1`. Malformed tree tables are outside the input contract, as in the source LeetCode function.
- The node limit follows the portable indexed-tree ABI. LeetCode allows 10,000 nodes; this benchmark uses a smaller bound to keep recursion depth portable across all nine targets.

## Algorithm and verification

The pinned C implementation recursively searches the left subtree, decrements the shared rank at each inorder visit, and returns immediately once the rank reaches zero. The ports preserve that traversal and early exit. The verifier compares all valid ranks over every ordered tree shape through seven nodes, seeded random BSTs, and balanced and skewed maximum-size trees; it also checks invalid roots and ranks.

The source is [TheAlgorithms C LeetCode `230.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/230.c); the problem statement is [LeetCode 230: Kth Smallest Element in a BST](https://leetcode.com/problems/kth-smallest-element-in-a-bst/).

Build with the `tree_rank` ABI family and record with `benchmarks/run_tree_rank.py`. Verify all ports with `python3 benchmarks/verify_kth_smallest_bst.py`.
