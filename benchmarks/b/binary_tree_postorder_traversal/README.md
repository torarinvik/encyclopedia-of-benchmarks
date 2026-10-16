# Binary tree postorder traversal

Write every node value in left-right-root postorder into caller-owned output storage and return the number of values written. The indexed tree stores each node as `[value, left_child_index, right_child_index]`; `-1` denotes a missing child.

## Contract

- Inputs contain 1 through 100 nodes. The root is any valid node-table index; the tree must be rooted, acyclic, and every node must be reachable exactly once.
- Node values are signed 64-bit integers. Output values use the same signed 64-bit representation.
- The caller provides output capacity for at least the node count. Invalid roots, child indices, disconnected nodes, or insufficient capacity return `-1`.
- Empty trees are outside this contract because the pinned `postOrderIterative` pushes and dereferences its root without a null check.

The pinned C++ source [iterative tree traversals](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/iterative_tree_traversals.cpp) writes a popped node, pushes its left child and then its right child, and reverses the collected sequence. This yields left-right-root postorder. The second indexed C++ source has the same traversal.

The pinned Java [`PostOrderTraversal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/PostOrderTraversal.java) and Ruby [`postorder_traversal.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/binary_trees/postorder_traversal.rb) also emit left-right-root node values. Their empty-root results are outside this package's nonempty input domain.

The C `recursive_traversals.c` and C++ `recursive_tree_traversal.cpp` sources also expose postorder; see the [full traversal guide](../binary_tree_traversal/README.md) for their pinned references.

[`workload.json`](workload.json) covers both child branches, negative values, nonzero roots, skewed trees, signed 64-bit boundaries, and malformed inputs.

| Language | Source |
| --- | --- |
| C | [`c/b/binary_tree_postorder_traversal.c`](../../../c/b/binary_tree_postorder_traversal.c) |
| C3 | [`c3/b/binary_tree_postorder_traversal.c3`](../../../c3/b/binary_tree_postorder_traversal.c3) |
| C++ | [`cpp/b/binary_tree_postorder_traversal.cpp`](../../../cpp/b/binary_tree_postorder_traversal.cpp) |
| Elisa | [`elisa/b/binary_tree_postorder_traversal.elisa`](../../../elisa/b/binary_tree_postorder_traversal.elisa) |
| Nim | [`nim/b/binary_tree_postorder_traversal.nim`](../../../nim/b/binary_tree_postorder_traversal.nim) |
| Odin | [`odin/b/binary_tree_postorder_traversal.odin`](../../../odin/b/binary_tree_postorder_traversal.odin) |
| Rust | [`rust/b/binary_tree_postorder_traversal.rs`](../../../rust/b/binary_tree_postorder_traversal.rs) |
| V | [`v/b/binary_tree_postorder_traversal.v`](../../../v/b/binary_tree_postorder_traversal.v) |
| Zig | [`zig/b/binary_tree_postorder_traversal.zig`](../../../zig/b/binary_tree_postorder_traversal.zig) |

The benchmark uses the `tree_value_output` ABI.
