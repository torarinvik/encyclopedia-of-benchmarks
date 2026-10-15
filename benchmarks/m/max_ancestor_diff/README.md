# Maximum ancestor difference

Find the largest absolute value difference between any tree node and one of its ancestors. The recursive search carries the minimum and maximum value seen along each root-to-node path, then compares each visited node against those bounds.

## Contract

- Input is a caller-owned table of at most 1,023 `[value, left_child_index, right_child_index]` triplets with one valid nonempty rooted binary tree. The root can have any table index; child index `-1` means absent.
- Values are in `[-100,000, 100,000]`, matching the source problem's range.
- Return the maximum absolute ancestor-to-descendant difference. Invalid roots or child indexes and out-of-range values return `-1`.
- The implementations use recursive depth-first traversal and caller-owned input storage. The node bound limits recursion depth to 1,023.

## Workload and verification

[`workload.json`](workload.json) covers singleton, branched, path-local extrema, the full value range, a nonzero root index, invalid indexes, and a 1,023-node path. [`benchmarks/verify_max_ancestor_diff.py`](../../verify_max_ancestor_diff.py) checks all nine ports against an independent iterative path-bounds oracle, every ordered tree shape through seven nodes, deterministic random trees, and the published workload.

The benchmark is based on [TheAlgorithms C LeetCode source `1026.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1026.c). Its DFS tracks the minimum and maximum values on each ancestor path.

Build with the `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
