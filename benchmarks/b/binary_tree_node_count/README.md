# Binary tree node count

Count the nodes reachable from a root in a bounded indexed binary tree. This captures the Haskell `numNodes` routine, which runs breadth-first traversal and returns the number of visited nodes.

## Contract

- The `tree_scalar` ABI supplies a node table of `[value, left_child, right_child]` triplets and a root index. `-1` denotes a missing child.
- The table contains 1 through 900 nodes. Payloads are any signed 64-bit values and do not affect the result.
- The root-reachable portion must be a proper tree. Unreachable table entries are ignored. A missing root, invalid child index, cycle, or shared child returns `-9,000,000,000,000,000,000`.
- The result is the number of reachable nodes. The node bound keeps the recursive ports' worst-case depth below Python's default recursion limit.

The independent oracle validates the reachable shape and counts nodes with an iterative stack. [`workload.json`](workload.json) includes single-node, branching, nonzero-root, ignored-payload, malformed, and maximum-depth cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_tree_node_count.c`](../../../c/b/binary_tree_node_count.c) |
| C3 | [`c3/b/binary_tree_node_count.c3`](../../../c3/b/binary_tree_node_count.c3) |
| C++ | [`cpp/b/binary_tree_node_count.cpp`](../../../cpp/b/binary_tree_node_count.cpp) |
| Elisa | [`elisa/b/binary_tree_node_count.elisa`](../../../elisa/b/binary_tree_node_count.elisa) |
| Nim | [`nim/b/binary_tree_node_count.nim`](../../../nim/b/binary_tree_node_count.nim) |
| Odin | [`odin/b/binary_tree_node_count.odin`](../../../odin/b/binary_tree_node_count.odin) |
| Rust | [`rust/b/binary_tree_node_count.rs`](../../../rust/b/binary_tree_node_count.rs) |
| V | [`v/b/binary_tree_node_count.v`](../../../v/b/binary_tree_node_count.v) |
| Zig | [`zig/b/binary_tree_node_count.zig`](../../../zig/b/binary_tree_node_count.zig) |

## Upstream source

- Haskell [`BinaryTree.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/BinaryTree/BinaryTree.hs)
