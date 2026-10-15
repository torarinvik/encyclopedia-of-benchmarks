# Lowest Common Ancestor of a Binary Tree

Given two distinct nodes in a binary tree, return their lowest common ancestor. The node table uses stable integer indexes so the result can identify the exact ancestor node.

## Contract

- Input is `[node_count, root_index, p_index, q_index, (value, left_index, right_index) * node_count]`.
- A node is `[signed value, left child index, right child index]`; child index `-1` means absent. Node indexes refer to rows in the table.
- The input must describe one rooted binary tree with 2..1,023 nodes. Node values are unique and in `[-1,000,000,000, 1,000,000,000]`; `p_index` and `q_index` are distinct valid nodes. These match the source problem's value and target guarantees while bounding storage for the shared benchmark ABI.
- Return the table index of the lowest common ancestor. Invalid packed trees or indexes return `-1`. Input is read only.
- Implementations derive both node-to-root paths from indexed parent links and compare their root-side prefixes. Time is O(n); auxiliary space is O(n).

## Workload

[`workload.json`](workload.json) covers the two published tree shapes, a target that is itself an ancestor, a nonzero root table index, a maximum-depth chain, and an invalid child index.

## Upstream source

- [TheAlgorithms/C LeetCode 236 at the pinned revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/236.c)
- [LeetCode 236 statement and constraints](https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-tree/description/)
