# Ceiling in a binary search tree

For a query key, return the smallest node value greater than or equal to the
key. The search follows the pinned Java implementation: return on equality;
move right when the current value is below the key; otherwise save the current
node as the best candidate and continue left.

## Contract

- Input is packed as `[node_count, root_index, key, (value,left,right)*]`.
  Child indexes are zero-based; `-1` means no child.
- The table represents one valid strict binary search tree with unique node
  values. The root may have any table index. An empty tree uses root index -1.
- There are 0 to 127 nodes. Node values and query keys are in
  `[-1,000,000, 1,000,000]`; negative node values are valid.
- Return the least node value greater than or equal to the key. If the tree is
  empty or no such value exists, return `INT64_MIN` as the null-result sentinel.
  This cannot collide with a node value; in particular, -1 remains a valid node
  value.
- Malformed packed headers, out-of-range indexes encountered by the search, or
  out-of-range values encountered on the search path return `INT64_MIN + 1`.
- The input is a valid BST by contract. The implementation keeps the source
  search complexity at O(height) and does not scan every node to validate the
  entire tree.

## Source note

The pinned Java implementation is the benchmark contract. Its prose comment
reverses the left/right directions, and its example claiming that a query of 10
returns 20 conflicts with the equality branch. The implementation returns the
equal node 10, and follows right for a node value below the key. The workload
records the implementation behavior.

## Workload and oracle

[`workload.json`](workload.json) covers exact matches, keys between values,
keys below and above the range, a valid node value of -1, and an empty tree.
The independent oracle scans the valid tree's node values for the least value
at least the key. All nine ports passed 2,673 oracle arrays each and all 14
workload records. Run
`python3 benchmarks/verify_i64_array_scalar.py --algorithms ceil_in_binary_search_tree --jobs 3 --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`
to check the oracle corpus and registered scalar workload.

## Pinned source

[TheAlgorithms/Java `CeilInBinarySearchTree.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/CeilInBinarySearchTree.java)
defines `getCeil(Node root, int key)` and returns a node or null.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/ceil_in_binary_search_tree.c`](../../../c/c/ceil_in_binary_search_tree.c) |
| C3 | [`c3/c/ceil_in_binary_search_tree.c3`](../../../c3/c/ceil_in_binary_search_tree.c3) |
| C++ | [`cpp/c/ceil_in_binary_search_tree.cpp`](../../../cpp/c/ceil_in_binary_search_tree.cpp) |
| Elisa | [`elisa/c/ceil_in_binary_search_tree.elisa`](../../../elisa/c/ceil_in_binary_search_tree.elisa) |
| Nim | [`nim/c/ceil_in_binary_search_tree.nim`](../../../nim/c/ceil_in_binary_search_tree.nim) |
| Odin | [`odin/c/ceil_in_binary_search_tree.odin`](../../../odin/c/ceil_in_binary_search_tree.odin) |
| Rust | [`rust/c/ceil_in_binary_search_tree.rs`](../../../rust/c/ceil_in_binary_search_tree.rs) |
| V | [`v/c/ceil_in_binary_search_tree.v`](../../../v/c/ceil_in_binary_search_tree.v) |
| Zig | [`zig/c/ceil_in_binary_search_tree.zig`](../../../zig/c/ceil_in_binary_search_tree.zig) |

The oracle is [`ceil_in_binary_search_tree_oracle.py`](../../ceil_in_binary_search_tree_oracle.py).
