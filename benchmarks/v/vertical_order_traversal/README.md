# Vertical order traversal

Return node values grouped by horizontal column, from the leftmost column to the rightmost. Within each column, preserve breadth-first order: top to bottom, then left to right for ties. This follows the pinned Java [`VerticalOrderTraversal.verticalTraversal`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/VerticalOrderTraversal.java).

The source runs a breadth-first traversal, assigning the root column 0, left children column -1 from their parent, and right children column +1. It appends each visited node to that column's list, then concatenates the lists in ascending column order. This is distinct from [`level_order_traversal`](../../l/level_order_traversal/README.md), which groups values by depth instead of column.

## Contract

- Input is an indexed table of up to 1,023 `[value, left_child_index, right_child_index]` triplets; `-1` means no child. The root may have any table index. Values are signed 32-bit integers, matching the Java node field.
- A nonempty table describes one valid rooted binary tree with every node reachable exactly once. Empty input uses root index `-1` and returns zero columns.
- The function writes values in vertical order and writes offsets delimiting each column, beginning with 0. It returns the column count. Empty output writes the single offset 0.
- Invalid trees and values return `-1`. Insufficient output, offset, or queue capacity returns `-2`.
- The exported function uses the caller-buffer layout of the existing `tree_level_order` ABI.

The workload uses the existing `tree_level_order_call` model to match that caller-buffer layout. In the workload, `expected_level_offsets` stores the boundaries between vertical columns. The independent oracle checks malformed cases, while the timing runner records successful calls only.
