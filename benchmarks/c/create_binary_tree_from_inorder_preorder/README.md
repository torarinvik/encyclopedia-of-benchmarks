# Create a binary tree from inorder and preorder traversals

Reconstruct an arbitrary binary tree from its preorder and inorder value sequences. The benchmark follows the pinned Java public default `createTree`: it selects the first preorder value as the root, locates that value in the current inorder interval, and partitions the remaining ranges for the left and right subtrees. The same source also offers `createTreeOptimized`, which uses a hash map; this package pins the default range-scan method.

The result is serialized with the repository's indexed-tree benchmark convention: each non-null node emits marker byte `1`, its signed 32-bit value in little-endian order, then its left and right subtrees; each null child emits marker byte `0`.

## Contract

- Input is a packed signed 64-bit array `[n, preorder[0..n], inorder[0..n]]`, with `0 <= n <= 63`. Each traversal value is a signed 32-bit integer.
- Both traversals must contain the same unique values. These conditions make the binary tree uniquely reconstructible; duplicates and inconsistent traversal pairs return `-1`.
- The function returns `n` and writes the tree encoding described above. For `n=0`, the Java method returns a null root and the adapter emits the single null marker byte. Insufficient output capacity returns `-2`.
- The ports use an explicit stack of traversal intervals to carry out the source method's recursive inorder partitioning. The bound keeps the source's recursive form shallow and the serialized output within 379 bytes.

This contract is distinct from [`bst_from_preorder`](../../b/bst_from_preorder/README.md), which takes one traversal and reconstructs only a strict BST. The tree-inorder traversal benchmark only visits an already-built tree.

[`workload.json`](workload.json) covers empty input, general trees, balanced and skewed trees, signed boundaries, duplicates, inconsistent traversals, and malformed packing.
