# Validate binary search tree

Return whether an indexed binary tree satisfies strict binary search tree ordering. Each node is checked against the full lower and upper bounds inherited from its ancestors, so a key can be rejected even when it is ordered correctly against its parent. The empty tree is valid.

## Contract

- Input is a caller-owned table of at most 1,023 `[signed 32-bit value, left child index, right child index]` triplets. Child index `-1` means absent.
- A nonempty input is one valid rooted binary tree. Every node is reachable exactly once, and the root can have any table index. An empty tree uses zero nodes and root index `-1`.
- Return `1` for a strict BST, `0` for a valid tree that violates strict ordering, and `-1` for an invalid root, child index, node value, or oversized table. Duplicate keys are invalid BSTs.
- The recursive bound checks use constant auxiliary storage. The node limit caps recursion depth at 1,023.

## Workload and verification

[`workload.json`](workload.json) includes empty and single-node trees, nonzero root indexes, signed 32-bit boundaries, duplicate and ancestor-bound violations, malformed indexes and values, and valid trees of maximum depth and size. [`benchmarks/verify_validate_bst.py`](../../verify_validate_bst.py) checks all nine ports against an independent iterative in-order oracle, all ordered tree shapes through seven nodes with valid and invalid key assignments, deterministic random trees and BSTs, and the published workload.

The benchmark is based on [TheAlgorithms C LeetCode source `98.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/98.c), which propagates strict lower and upper bounds through recursive calls.

Build with the shared `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
