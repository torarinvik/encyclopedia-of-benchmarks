# Flatten Binary Tree to Linked List

Flatten a binary tree in place into a right-child chain in preorder, matching the pinned Python routine. The preorder begins at the supplied root and visits each node, then its original left subtree, then its original right subtree.

## Contract

- Pack the tree as `[root_index, value0, left0, right0, ...]`. Each node value is a signed 32-bit integer. Child index `-1` means absent; node IDs may appear in any table order.
- Inputs contain 0 through 1,023 nodes and have height at most 512. A nonempty input must be one rooted tree with every node reachable exactly once. The empty tree is encoded as `[-1]`.
- The ABI leaves its input unchanged and serializes the transformed copy in original node-ID order as little-endian signed 64-bit `[value, flattened_left_index, flattened_right_index]` triplets. Every flattened left index is `-1`; right indexes form the preorder chain, ending in `-1`. The return value is the node count.
- Invalid layouts, roots, links, values, cycles, shared children, unreachable nodes, or excessive height return `-1`. Insufficient output capacity returns `-2`.
- The upstream routine recursively flattens the left subtree, moves it to the right link, clears the left link, scans to the resulting tail, appends the original right subtree, and then recursively flattens that subtree. The tail scan makes its worst-case work O(n²); recursion uses O(h) stack space. The benchmark ports preserve this mutation order on a copied indexed tree.

## Workload

[`workload.json`](workload.json) covers the empty tree, a singleton, a nonzero root with both subtrees, a right chain, signed value boundaries, and malformed trees. Output triplets remain in original node-ID order even when preorder visits nodes in a different order.

## Upstream source

- [TheAlgorithms/Python `flatten_binarytree_to_linkedlist.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/flatten_binarytree_to_linkedlist.py)
