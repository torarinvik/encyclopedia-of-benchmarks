# BST From Preorder

Reconstruct a strict binary search tree from its preorder sequence and serialize the resulting tree structure.

## Contract

- Input is a preorder array of 1 to 15 unique signed 32-bit keys.
- The values must be a valid preorder traversal of a BST with strict ordering; duplicates and malformed traversals return `-1`.
- Return the number of nodes. Output uses preorder serialization: `0` marks a null child; `1` marks a node and is followed by its signed 32-bit value in little-endian byte order, then the left and right subtrees.
- Insufficient output capacity returns `-2` without writing output.
- The implementation validates the traversal and reconstructs the tree recursively by partitioning at the first key greater than the root.

## Reviewed TheAlgorithms source

The pinned [C LeetCode file `1008.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1008.c) recursively partitions preorder values at each root and allocates the left and right subtrees. This benchmark uses a bounded caller-owned output buffer and makes invalid traversals explicit.

## Workload and verification

[`workload.json`](workload.json) covers balanced and skewed trees, negative keys, invalid traversals, duplicates, and capacity handling. [`benchmarks/verify_bst_from_preorder.py`](../../verify_bst_from_preorder.py) checks all nine ports against independent BST insertion and serialization over exhaustive small permutations and deterministic random cases.

## Implementations

All nine implementations use the shared i64-array/bytes-output ABI.
