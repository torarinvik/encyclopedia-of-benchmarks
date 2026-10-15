# Symmetric binary tree

Check whether a binary tree is its own mirror. The benchmark compares the root's left and right subtrees recursively: corresponding node values must match, and each node's left child is paired with the opposite node's right child.

## Contract

- The input is a caller-owned table of at most 1,023 `[value, left_child_index, right_child_index]` triplets. Values are signed 32-bit integers; child index `-1` means absent.
- A nonempty table describes one valid rooted binary tree. The root can appear at any table index; an empty tree uses root index `-1`.
- Return `1` for a symmetric tree, `0` for a nonsymmetric tree, and `-1` for an invalid root or an invalid child index encountered during comparison. Values may repeat.
- The implementations use the source algorithm's recursive mirrored-pair comparison and require no architecture-specific instructions.
- The node limit bounds the maximum possible comparison depth to 511 recursive pairs, so the same workload remains practical across the supported runtimes.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton trees, matching and mismatching values, shape mismatches, signed boundaries, a nonzero root index, invalid roots, and mirrored chains that reach 511 recursive pairs. [`benchmarks/verify_symmetric_tree.py`](../../verify_symmetric_tree.py) checks all nine ports against a separate tree-shape oracle, every ordered binary-tree shape through seven nodes, deterministic generated trees, deep symmetric inputs, invalid roots, and every published workload case.

The [C LeetCode file `101.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/101.c), [Python `symmetric_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/symmetric_tree.py), and [Java `CheckTreeIsSymmetric.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/CheckTreeIsSymmetric.java) all perform the same recursive mirror check. The numeric C candidate and Java filename are recorded as aliases of the canonical Python-named benchmark.

Build with the `tree_symmetric` ABI family and record with `benchmarks/run_tree_symmetric.py`.
