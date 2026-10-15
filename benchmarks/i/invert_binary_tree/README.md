# Invert Binary Tree

Mirror a binary tree by recursively exchanging every node's left and right children, following C LeetCode 226. The PHP `InvertBinaryTree` method and Python `Node.mirror` method use the same recursive operation and are cataloged as aliases.

## Contract

- Pack the tree as `[root_index, value0, left0, right0, ...]`, with one signed 32-bit value and two child indexes per node. Child index `-1` means absent. Node IDs may appear in any table order.
- Inputs contain 0 through 1,023 nodes and have height at most 512. Nonempty inputs must form one rooted tree with every node reachable exactly once. Invalid roots, links, values, lengths, cycles, shared children, or unreachable nodes return `-1`.
- The input table is read only. Output is the transformed node table in original node-ID order, serialized as little-endian signed 64-bit `[value, mirrored_left, mirrored_right]` triplets. The result is the node count. Insufficient output capacity returns `-2`.
- The source operation recursively swaps each node's child links in O(n) time and O(h) call-stack space. The shared ABI also validates the indexed tree and serializes each transformed node, so measured calls use O(n) validation state and output storage.

## Workload and verification

[`workload.json`](workload.json) includes empty and singleton trees, a nonzero root ID, a chain, signed value boundaries, malformed trees, and a balanced 255-node tree. [`benchmarks/verify_invert_binary_tree.py`](../../verify_invert_binary_tree.py) checks all nine ports against an independent structural oracle, every ordered binary-tree shape through seven nodes, deterministic generated trees up to 1,023 nodes, maximum accepted depth, malformed structures, and insufficient output capacity.

## Upstream sources

- [TheAlgorithms/C LeetCode 226](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/226.c)
- [TheAlgorithms/PHP `InvertBinaryTree.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/InvertBinaryTree/InvertBinaryTree.php)
- [TheAlgorithms/Python `mirror_binary_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/mirror_binary_tree.py)
