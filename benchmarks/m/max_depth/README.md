# Maximum depth of a binary tree

Return the largest number of nodes along any root-to-leaf path. The recursive implementation computes one plus the larger depth of the left and right subtrees; a null tree returns zero, matching the source algorithm.

## Contract

- Input is a caller-owned indexed table of at most 1,023 `[value, left_child_index, right_child_index]` triplets. Values are ignored. Child index `-1` means absent.
- A nonempty input is one valid rooted binary tree. The root can have any table index. An empty tree uses zero nodes and root index `-1`.
- Return the maximum node count on a root-to-leaf path. Invalid roots or child indexes and tables over 1,023 nodes return `-1`.
- Implementations use recursive depth-first traversal. The node bound limits recursion depth to 1,023.

## Workload and verification

[`workload.json`](workload.json) covers an empty tree, singleton, balanced and unbalanced trees, a nonzero root index, signed value extremes, invalid indexes, and a 1,023-node path. [`benchmarks/verify_max_depth.py`](../../verify_max_depth.py) compares all nine ports with an independent iterative traversal oracle, every ordered tree shape through seven nodes, deterministic random trees, invalid inputs, and the published workload.

The benchmark follows [TheAlgorithms C LeetCode source `104.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/104.c), which returns one plus the larger recursive child depth.

Build with the shared `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
