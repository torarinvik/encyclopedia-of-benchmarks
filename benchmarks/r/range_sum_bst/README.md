# Range Sum of BST

Return the sum of node values in the inclusive interval `[low, high]`. The benchmark uses an indexed binary tree with node records `[value, left_child_index, right_child_index]`; `-1` denotes a missing child. Query bounds and root index are explicit ABI arguments. Values are unique and the tree obeys strict BST ordering.

## Contract

- The table contains between zero and 1,023 nodes. An empty tree has root index `-1` and returns zero.
- Each node value and each query bound is in `[1, 100,000]`; `low <= high`.
- A nonempty input is one valid rooted BST, every node is reachable exactly once, and values are unique. The root may have any table index.
- Invalid tables, roots, values, or bounds return `-1`. Valid answers fit signed 64-bit arithmetic (the maximum supported sum is 102,300,000).
- The 1,023-node limit follows the existing tree benchmark ABI. The LeetCode statement permits up to 20,000 nodes, so this benchmark defines a smaller portable workload bound.

## Algorithm and verification

The pinned C implementation checks whether the current value is in range, adds it when it is, and recursively visits both children on every node. These ports preserve that full traversal, including when the BST ordering could skip a subtree. The verifier uses an independent iterative oracle, validates tree structure and strict BST ordering, exercises all ordered shapes through seven nodes, seeded random BSTs, boundary queries, malformed trees, and maximum-size trees.

The source is [TheAlgorithms C LeetCode `938.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/938.c); the problem statement is [LeetCode 938: Range Sum of BST](https://leetcode.com/problems/range-sum-of-bst/).

Build with the `tree_range_sum` ABI family and record with `benchmarks/run_tree_range_sum.py`. Verify all ports with `python3 benchmarks/verify_range_sum_bst.py`.
