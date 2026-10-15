# Diameter of a binary tree

This benchmark follows the pinned Python `Node.diameter()` method. For the selected node, it returns the number of nodes on the longest path that passes through that node: `left.depth() + right.depth() + 1`. A missing child has depth zero and a leaf therefore returns 1.

The pinned module describes the diameter as the longest path between any two endpoints, but its method does not take a maximum over descendant nodes. For example, when a root has one child whose two child subtrees are both deeper, `Node.diameter()` returns the path through the root, even though the longest path in the whole tree passes through that child. This package preserves the callable's behavior and names that receiver-centered result explicitly.

## Contract

- Input uses the indexed tree scalar ABI: a table of 1 through 1,023 `[value, left_index, right_index]` rows and a selected `root_index`. `-1` means a child is absent. The selected node must be the root of a valid tree in which every row is reachable exactly once through child links.
- Node values are ignored, as they are by the pinned method. Child indexes must be `-1` or indexes within the table.
- Return the count of nodes on the longest path through the selected node. This is a node count, not an edge count. A single node returns 1. Invalid tree shape, child index, root, or node count returns `-1`.
- The implementation computes subtree heights recursively in O(n) time and O(h) call stack, with `h ≤ 1,023`.

The source is [TheAlgorithms/Python `diameter_of_binary_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/diameter_of_binary_tree.py). This package is distinct from [`binary_tree_maximum_path_sum`](../../b/binary_tree_maximum_path_sum/README.md), which sums node values along any path, and [`max_depth`](../../m/max_depth/README.md), which returns only the selected subtree height.

[`workload.json`](workload.json) includes the pinned examples, a case where the longest whole-tree path lies below the selected root, nonzero roots, one-sided paths, and malformed tree shapes.

| Language | Source |
| --- | --- |
| C | [`c/d/diameter_of_binary_tree.c`](../../../c/d/diameter_of_binary_tree.c) |
| C3 | [`c3/d/diameter_of_binary_tree.c3`](../../../c3/d/diameter_of_binary_tree.c3) |
| C++ | [`cpp/d/diameter_of_binary_tree.cpp`](../../../cpp/d/diameter_of_binary_tree.cpp) |
| Elisa | [`elisa/d/diameter_of_binary_tree.elisa`](../../../elisa/d/diameter_of_binary_tree.elisa) |
| Nim | [`nim/d/diameter_of_binary_tree.nim`](../../../nim/d/diameter_of_binary_tree.nim) |
| Odin | [`odin/d/diameter_of_binary_tree.odin`](../../../odin/d/diameter_of_binary_tree.odin) |
| Rust | [`rust/d/diameter_of_binary_tree.rs`](../../../rust/d/diameter_of_binary_tree.rs) |
| V | [`v/d/diameter_of_binary_tree.v`](../../../v/d/diameter_of_binary_tree.v) |
| Zig | [`zig/d/diameter_of_binary_tree.zig`](../../../zig/d/diameter_of_binary_tree.zig) |
