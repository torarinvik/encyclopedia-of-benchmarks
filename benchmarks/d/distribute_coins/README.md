# Distribute Coins in Binary Tree

Return the minimum number of one-coin moves needed to give every node exactly one coin. A move transfers one coin along one parent-child edge. The ports use postorder depth-first traversal: each subtree returns its excess above one coin per node, and each child edge contributes the absolute coin flow across it. This is equivalent to the pinned C implementation's null-subtree excess of one and its absolute per-edge transfer count.

## Contract

- The input is an indexed table of up to 100 `[coin_count, left_child_index, right_child_index]` triplets and a root index. Child index `-1` means absent; the root can have any table index.
- Values are integers from 0 to 100, the table is one valid rooted binary tree, and the total coin count equals the number of nodes. An empty tree uses zero nodes and root index `-1` and returns zero.
- Invalid roots, node tables, child indexes, coin values, coin totals, cycles, duplicate parents, or disconnected nodes return `-1`.
- The result counts individual edge transfers. The source problem's maximum of 100 nodes keeps the result within a signed 32-bit integer.

## Workload and verification

[`workload.json`](workload.json) covers empty and singleton trees, surplus and deficit subtrees, branching and skewed trees, nonzero root indexes, invalid inputs, and a 100-node path. [`benchmarks/verify_distribute_coins.py`](../../verify_distribute_coins.py) checks the ports against an independent iterative postorder oracle across all ordered shapes through seven nodes, deterministic random trees up to 100 nodes, malformed trees, and the published workload.

The source is [TheAlgorithms C LeetCode `979.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/979.c); the problem statement is [LeetCode 979: Distribute Coins in Binary Tree](https://leetcode.com/problems/distribute-coins-in-binary-tree/).

Build with the shared `tree_scalar` ABI family and record with `benchmarks/run_tree_scalar.py`.
