# Binary tree node sum

The pinned Python `BinaryTreeNodeSum` object performs a depth first traversal and yields the sum of the values in its root node and every descendant.

## Contract

- The `tree_scalar_call` ABI encodes each node as `[value, left_index, right_index]`; child index `-1` means no child.
- A nonempty input tree has at most 900 nodes. This bounds the source's recursive traversal to at most 900 nested calls, below Python's default recursion limit; the root may be any valid table index.
- Node values are in `[-1,000,000,000, 1,000,000,000]`, so every possible sum fits signed 64-bit range.
- The root-reachable portion must form a proper acyclic tree. Table entries outside that portion are ignored. The result is the sum of its nodes.
- Invalid empty trees, roots, child indices, values, and cycles return `-9,000,000,000,000,000,000`, which is outside the valid sum range.
- The indexed representation is an ABI adaptation of the source's pointer-linked `Node` object.

The source uses recursive depth first traversal and O(n) call-stack space. The ports retain recursive traversal. A total node limit of 900 bounds the deepest possible path, stays below Python's default recursion limit, and limits the work needed to reject cyclic inputs.

## Workload

[`workload.json`](workload.json) includes the pinned source's incremental tree examples, negative values, an arbitrary root index, value bounds, and invalid shape cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_tree_node_sum.c`](../../../c/b/binary_tree_node_sum.c) |
| C3 | [`c3/b/binary_tree_node_sum.c3`](../../../c3/b/binary_tree_node_sum.c3) |
| C++ | [`cpp/b/binary_tree_node_sum.cpp`](../../../cpp/b/binary_tree_node_sum.cpp) |
| Elisa | [`elisa/b/binary_tree_node_sum.elisa`](../../../elisa/b/binary_tree_node_sum.elisa) |
| Nim | [`nim/b/binary_tree_node_sum.nim`](../../../nim/b/binary_tree_node_sum.nim) |
| Odin | [`odin/b/binary_tree_node_sum.odin`](../../../odin/b/binary_tree_node_sum.odin) |
| Rust | [`rust/b/binary_tree_node_sum.rs`](../../../rust/b/binary_tree_node_sum.rs) |
| V | [`v/b/binary_tree_node_sum.v`](../../../v/b/binary_tree_node_sum.v) |
| Zig | [`zig/b/binary_tree_node_sum.zig`](../../../zig/b/binary_tree_node_sum.zig) |

## Upstream source

- [TheAlgorithms/Python `binary_tree_node_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/binary_tree_node_sum.py)
- [Olden `treeadd`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/treeadd) uses the same recursive node-plus-left-and-right-subtree summation; its full value-one tree and repeated passes are source workload details rather than a separate algorithm, so it is cross-referenced here instead of kept as a duplicate package.
