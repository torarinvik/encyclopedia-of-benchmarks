# Print top view of a tree

Return one visible node for each horizontal distance in a binary tree. The package follows the pinned Java [`PrintTopViewofTree.printTopView`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/PrintTopViewofTree.java): breadth-first search starts at distance 0, left edges subtract 1, and right edges add 1. The first node dequeued at a distance is selected. Since the source prints at selection time, output order is first-discovery order in BFS (root, then breadth-first left-to-right discoveries), not ascending horizontal distance.

This returns only the top view. It is distinct from [`vertical_order_traversal`](../../v/vertical_order_traversal/README.md), which emits every node grouped by ascending horizontal distance.

## Contract

- Input is an indexed table of at most 1,023 `[value, left_child_index, right_child_index]` triplets. Values are signed 32-bit integers, matching the Java `TreeNode.key`; `-1` marks a missing child.
- A nonempty table must describe one valid rooted binary tree. The root may use any table index. Empty input uses root index `-1`.
- The function writes the selected top-view values in the source's BFS discovery order and returns their count. `column_offsets` is `[0, 1, ..., count]`, marking each output as one selected item. Empty input returns 0 and writes offset `[0]`.
- Invalid tree structure or values return `-1`. Insufficient output, offset, or queue capacity returns `-2`.
- The ports use the caller-buffer layout of the existing `tree_level_order` ABI.

The source method returns `void` and prints selected keys; the benchmark adapts that observable sequence to a returned count and output buffer. Hash-set iteration order does not affect output because the set is used only for membership, while printing happens immediately during BFS.
