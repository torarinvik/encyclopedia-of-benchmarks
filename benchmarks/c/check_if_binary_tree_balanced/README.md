# Check if binary tree balanced

Return whether every node has left and right subtree heights that differ by at most one. This package ports the recursive one-pass method `isBalancedRecursive` from [TheAlgorithms Java, pinned source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/CheckIfBinaryTreeBalanced.java).

The Java method computes subtree heights during a postorder traversal and records imbalance as soon as it finds one. This is distinct from [`balanced_binary_tree`](../../b/balanced_binary_tree/README.md), whose source recomputes subtree heights before recursively checking each node. The Java file also contains an iterative postorder alternative; this benchmark represents its recursive method.

## Contract

- Input is a caller-owned indexed table of up to 1,023 `[value, left_child_index, right_child_index]` triplets. Values are ignored; `-1` marks an absent child. The root may have any index.
- A nonempty table describes one valid rooted binary tree, with each node reachable exactly once. Empty input uses root index `-1` and is balanced.
- Return `1` for balanced trees and `0` otherwise. Invalid roots, child indexes, or tables larger than 1,023 nodes return `-1`.
- The recursive traversal uses no heap allocation. The node limit bounds recursion depth.

The workload uses the shared `tree_scalar` ABI and `tree_scalar_call` comparison model.
