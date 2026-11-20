# Weight-Balanced Leaf Tree ordered multiset

Input is `[Q,(operation,argument)*Q]`, with at most 64 operations. Operation 0 inserts one key; operation 1 removes one occurrence if present; operation 2 returns the number of keys strictly below its argument; operation 3 returns a zero-based selection; operations 4 and 5 return the strict predecessor and successor. Keys are in `-128..127`; selection indices are in `0..63`. Missing selections or neighbors return `-129`. Repeated keys are retained. Insertion descends left when the key equals a subtree's left maximum, so equal keys are inserted before existing equals; removal erases the leftmost equal key. Missing removals leave the multiset unchanged. Malformed input returns `-1`.

The primary kernel stores keys in leaves and combines ordered subtrees in internal nodes. It uses the OI Wiki merge-based WBLT variant with `alpha=1/4`: a child is too heavy when its sibling has at most one third of its weight. An imbalanced node is cut and its ordered children are merged again. This is a weight-ratio invariant and cut/merge repair kernel, distinct from the local Size Balanced Tree's grandchild-size inequalities and rotations. The checksum adds `step*(answer+129)` for each query using one-based operation positions; updates contribute nothing. The independent reference maintains a sorted multiset directly.

The current [OI Wiki WBLT article](https://oi-wiki.org/ds/wblt/) is used for algorithm description only. Code, prose, examples, and fixtures were independently authored.

| Language | Port |
|---|---|
| C | [c/w/weight_balanced_leaf_tree_order_statistics.c](../../../c/w/weight_balanced_leaf_tree_order_statistics.c) |
| C3 | [c3/w/weight_balanced_leaf_tree_order_statistics.c3](../../../c3/w/weight_balanced_leaf_tree_order_statistics.c3) |
| C++ | [cpp/w/weight_balanced_leaf_tree_order_statistics.cpp](../../../cpp/w/weight_balanced_leaf_tree_order_statistics.cpp) |
| Elisa | [elisa/w/weight_balanced_leaf_tree_order_statistics.elisa](../../../elisa/w/weight_balanced_leaf_tree_order_statistics.elisa) |
| Mojo | [mojo/w/weight_balanced_leaf_tree_order_statistics.mojo](../../../mojo/w/weight_balanced_leaf_tree_order_statistics.mojo) |
| Nim | [nim/w/weight_balanced_leaf_tree_order_statistics.nim](../../../nim/w/weight_balanced_leaf_tree_order_statistics.nim) |
| Odin | [odin/w/weight_balanced_leaf_tree_order_statistics.odin](../../../odin/w/weight_balanced_leaf_tree_order_statistics.odin) |
| Rust | [rust/w/weight_balanced_leaf_tree_order_statistics.rs](../../../rust/w/weight_balanced_leaf_tree_order_statistics.rs) |
| V | [v/w/weight_balanced_leaf_tree_order_statistics.v](../../../v/w/weight_balanced_leaf_tree_order_statistics.v) |
| Zig | [zig/w/weight_balanced_leaf_tree_order_statistics.zig](../../../zig/w/weight_balanced_leaf_tree_order_statistics.zig) |
