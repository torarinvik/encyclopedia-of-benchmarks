# Sum of left leaves

Sum the values of leaf nodes that are left children of their parent. The root is never counted as a left leaf. The recursive traversal carries whether the current node was reached through a left edge.

## Contract

- Input is a caller-owned indexed table of at most 1,023 `[value, left_child_index, right_child_index]` triplets. Child index `-1` means absent.
- A nonempty input is one valid rooted binary tree. The root can have any table index. An empty tree uses zero nodes and root index `-1`.
- Node values are in `[-1,000, 1,000]`. Return the signed sum of left-leaf values; a single-node tree returns zero.
- Invalid roots, child indexes, values, and tables over 1,023 nodes return `-1`. Internal recursion uses a separate sentinel so a valid sum of `-1` remains representable.
- The implementations use recursive traversal and caller-owned storage. The node bound limits recursion depth to 1,023.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton trees, the LeetCode example, negative leaves, a valid result equal to the invalid-result code, nonzero roots, invalid inputs, a 1,023-node path, and a complete tree with many left leaves. [`benchmarks/verify_sum_of_left_leaves.py`](../../verify_sum_of_left_leaves.py) checks all nine ports against an independent iterative oracle, every ordered tree shape through seven nodes, deterministic random trees, and the published workload.

The benchmark follows [TheAlgorithms C LeetCode source `404.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/404.c), which recursively sums the left subtree when a left child is a leaf and otherwise recurses through both children.

Build with the shared `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
