# Binary-tree maximum path sum

Return the largest sum of values along any nonempty path in the tree. A path follows parent-child edges, can begin and end at any nodes, and never visits a node twice. The recursive depth-first search carries the best one-sided gain upward and updates a separate maximum with paths that join both child branches.

## Contract

- Input is a caller-owned indexed table of at most 1,023 `[value, left_child_index, right_child_index]` triplets. Child index `-1` means absent.
- The input is one valid, nonempty rooted binary tree. The root can have any table index.
- Node values are in `[-1,000, 1,000]`. Return the largest sum over any nonempty connected path. Invalid roots, child indexes, values, or tables over 1,023 nodes return `-1`.
- The implementations use recursive depth-first traversal and caller-owned storage. The node bound limits recursion depth to 1,023.

## Workload and verification

[`workload.json`](workload.json) covers the Python and LeetCode source examples, all-negative values, a best path contained in a subtree, nonzero roots, invalid indexes and values, and maximum-size path and complete trees. [`benchmarks/verify_binary_tree_maximum_path_sum.py`](../../verify_binary_tree_maximum_path_sum.py) checks all nine ports against an independent iterative postorder oracle, every ordered tree shape through seven nodes, deterministic random trees, and the published workload.

The benchmark combines [TheAlgorithms C LeetCode source `124.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/124.c) with the same-semantics [Python `binary_tree_maximum_path_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/binary_tree_maximum_path_sum.py). The C file's `LOWER_BOUND` declaration is missing a semicolon; the ports implement its evident intended recurrence.

Build with the shared `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
