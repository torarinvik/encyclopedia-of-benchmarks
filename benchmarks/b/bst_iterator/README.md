# BST Iterator

The BST iterator eagerly materializes a binary search tree's in-order values, then serves them one at a time through `hasNext` and `next` behavior. This benchmark keeps that two-phase design: it first builds the ordered value array, then consumes it and returns an order-sensitive checksum.

## Contract

- Input is a caller-owned indexed tree of up to 1,023 `[value, left_child_index, right_child_index]` signed 64-bit triplets. Child index `-1` means absent; values are limited to -100,000 through 100,000.
- A nonempty input is a strict binary search tree with unique values, one parent for each non-root node, and every node reachable exactly once. The root may have any table index. An empty tree uses root index `-1`.
- The iterator reports `hasNext == true` before each returned value, yields values in ascending in-order order, then reports `hasNext == false`. The result is `sum((one_based_next_index) * (next_value + 100001))`; an empty tree returns zero.
- Invalid roots, child indexes, value order, disconnected/repeated nodes, and tables over 1,023 nodes return `-1`.

The implementation uses a fixed-size explicit traversal stack and value array, so it allocates no memory and does not depend on machine-specific instructions.

## Reviewed source

The pinned [C LeetCode 173 source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/173.c) counts the nodes, recursively writes an in-order sequence into an array, and advances an index in `next`. This contract retains eager materialization and iterator consumption while making empty trees and all allowed key values well-defined.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton trees, balanced and skewed trees, signed boundaries, shuffled node IDs, and a 1,023-node chain. [`benchmarks/verify_bst_iterator.py`](../../verify_bst_iterator.py) checks all nine ports against an independent tree and in-order oracle over every ordered tree shape through eight nodes, deterministic random BSTs, malformed tables, and the published workloads.

Build with the shared `tree_scalar` ABI and record with `benchmarks/run_tree_scalar.py`.
