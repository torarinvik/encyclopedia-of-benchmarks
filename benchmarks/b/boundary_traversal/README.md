# Binary tree boundary traversal

This benchmark returns the boundary of an indexed binary tree using the recursive `boundaryTraversal` method in the pinned Java source.

## Contract

The `tree_value_output` ABI receives node records as `[value, left_child_index, right_child_index]`, with the root index passed separately. Child index `-1` denotes a missing child. The benchmark accepts 0..100 nodes and signed 32-bit node values. An empty tree uses root `-1` and returns zero values; a nonempty tree must be a valid rooted binary tree whose nodes are all reachable exactly once. The caller provides output capacity of at least the node count.

The method emits, in order:

1. The root if it is not a leaf.
2. The left boundary, excluding leaves, preferring a left child and otherwise taking the right child.
3. All leaves from left to right.
4. The right boundary, excluding leaves, in reverse order, preferring a right child and otherwise taking the left child.

A leaf root appears once through the leaf traversal. When the root has no left child, the source's left-boundary fallback follows its right child, and the right-boundary pass is skipped. Success returns the number of output values. An invalid tree or insufficient capacity returns `-1` without output.

## Source and method

Pinned source: [TheAlgorithms/Java `BoundaryTraversal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/BoundaryTraversal.java).

The class also provides an iterative method with the same order. This benchmark measures the documented recursive `boundaryTraversal` method. The result is a boundary sequence, distinct from the preorder, inorder, and postorder traversal packages, which visit every node according to one depth-first order without separating side boundaries.

`workload.json` covers balanced and skewed trees, a right boundary that falls back to left children, a singleton, an empty tree, and invalid tree/capacity cases. All nine ports use the existing `tree_value_output` ABI.
