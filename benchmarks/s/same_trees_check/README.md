# Same trees check

Compare two binary trees breadth first. The trees are equal when corresponding nodes have the same value and matching left and right child positions; corresponding missing nodes also match. The result is `1` for equal trees, `0` for a difference, and `-1` for malformed packed input or an invalid indexed tree.

## Contract

- The input is `[n1, root1, rows1..., n2, root2, rows2...]`. Each row is `[signed 32-bit value, left child index, right child index]`; child index `-1` means absent. Each nonempty tree root is an index from `0` to `n-1`. An empty tree has `n=0` and root `-1`.
- Each tree contains 0 through 1,023 nodes, and the two trees together contain at most 1,023 nodes. Each is either empty or a valid rooted tree with every node reachable exactly once.
- The return value is `1` when both roots are null or the two trees match in shape and value, and `0` when only one root is null or a value/child position differs. Invalid packed length, root, child index, value range, or tree shape returns `-1`.
- The implementation uses breadth-first queues and runs in O(n1+n2) time and space.

This follows the pinned Java [`SameTreesCheck.check`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/SameTreesCheck.java). The source accepts node references, including `null`; the packed contract maps two null roots to two empty trees and one null root to an empty tree paired with a nonempty tree. It compares Java `int` node values, represented here as signed 32-bit integers. This differs from [`symmetric_tree`](../symmetric_tree/README.md), which compares a tree with its own mirror, and from [`univalued_binary_tree`](../../u/univalued_binary_tree/README.md), which checks values within one tree.

[`workload.json`](workload.json) covers two null roots, one null root, matching trees, value and shape mismatches, nonzero root indexes, and invalid tree encodings.

| Language | Source |
| --- | --- |
| C | [`c/s/same_trees_check.c`](../../../c/s/same_trees_check.c) |
| C3 | [`c3/s/same_trees_check.c3`](../../../c3/s/same_trees_check.c3) |
| C++ | [`cpp/s/same_trees_check.cpp`](../../../cpp/s/same_trees_check.cpp) |
| Elisa | [`elisa/s/same_trees_check.elisa`](../../../elisa/s/same_trees_check.elisa) |
| Nim | [`nim/s/same_trees_check.nim`](../../../nim/s/same_trees_check.nim) |
| Odin | [`odin/s/same_trees_check.odin`](../../../odin/s/same_trees_check.odin) |
| Rust | [`rust/s/same_trees_check.rs`](../../../rust/s/same_trees_check.rs) |
| V | [`v/s/same_trees_check.v`](../../../v/s/same_trees_check.v) |
| Zig | [`zig/s/same_trees_check.zig`](../../../zig/s/same_trees_check.zig) |
