# Move-to-root BST access trace

This profile builds an ordinary binary search tree from a supplied insertion
order, then applies the move-to-root heuristic to a bounded sequence of
accesses. After each successful search, it repeatedly rotates that accessed
node with its parent until the node becomes the root. Failed searches do not
restructure the tree.

## Contract

- Input is `[N,initial_keys[N],Q,access_keys[Q]]`, with `0<=N<=16` and
  `0<=Q<=32`. Keys are unique in the initial sequence and all keys lie in
  `[-100,100]`; accesses may miss.
- The initial BST is built by ordinary insertion in input order. Every access
  starts at the current root. Its cost is the number of visited nodes, including
  the matched node or the final node before a miss.
- A hit moves the accessed node to the root using successive single rotations
  with its parent. A miss leaves the tree unchanged.
- Return `sum((one_based_access_index)*(visited_node_count))`. Empty-tree
  accesses cost zero. Malformed framing, duplicate initial keys, out-of-range
  keys, or null input returns `-1`.
- The result is at most 8,448. The primary stores the tree in bounded
  parent/child arrays; the independent reference uses node objects and explicit
  parent links.

The single-rotation rule is distinct from [`splay_tree`](../../s/splay_tree/README.md):
splaying selects zig, zig-zig, or zig-zag restructures in pairs, while this
profile rotates only the accessed node upward one edge at a time. The workload
includes a left-left path whose second and third access costs distinguish these
transitions.

## Provenance and suite

The candidate came from NIST's [Dictionary of Algorithms and Data Structures
type index](https://xlinux.nist.gov/dads/termsType.html). The method is described
by Allen and Munro, [“Self-Organizing Binary Search Trees”](https://doi.org/10.1145/322092.322094).
The profile is clean-room and registered in the shared `i64_array_scalar`
suite. Maximum valid input is 50 words; the 51-word parse bound admits a
trailing-word rejection case. The fixed workspace is 4,096 bytes.

| Language | Port |
| --- | --- |
| C | [`c/m/move_to_root_bst_access_trace.c`](../../../c/m/move_to_root_bst_access_trace.c) |
| C3 | [`c3/m/move_to_root_bst_access_trace.c3`](../../../c3/m/move_to_root_bst_access_trace.c3) |
| C++ | [`cpp/m/move_to_root_bst_access_trace.cpp`](../../../cpp/m/move_to_root_bst_access_trace.cpp) |
| Elisa | [`elisa/m/move_to_root_bst_access_trace.elisa`](../../../elisa/m/move_to_root_bst_access_trace.elisa) |
| Mojo | [`mojo/m/move_to_root_bst_access_trace.mojo`](../../../mojo/m/move_to_root_bst_access_trace.mojo) |
| Nim | [`nim/m/move_to_root_bst_access_trace.nim`](../../../nim/m/move_to_root_bst_access_trace.nim) |
| Odin | [`odin/m/move_to_root_bst_access_trace.odin`](../../../odin/m/move_to_root_bst_access_trace.odin) |
| Rust | [`rust/m/move_to_root_bst_access_trace.rs`](../../../rust/m/move_to_root_bst_access_trace.rs) |
| V | [`v/m/move_to_root_bst_access_trace.v`](../../../v/m/move_to_root_bst_access_trace.v) |
| Zig | [`zig/m/move_to_root_bst_access_trace.zig`](../../../zig/m/move_to_root_bst_access_trace.zig) |
