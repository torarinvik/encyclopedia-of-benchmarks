# Size Balanced Tree ordered set

Input is `[Q,(operation,argument)*Q]` with at most 128 operations. Operation 0 inserts a unique key in `-1024..1023`; repeating an existing key changes nothing. Operation 1 returns the number of keys strictly below its key. Operation 2 requests a zero-based order statistic for an index in `0..127`. Operations 3 and 4 return the strict predecessor and successor. Missing order statistics or neighbors use sentinel `-1025`; malformed input returns `-1`.

The ports store subtree sizes and restore the Size Balanced Tree inequalities with single or double rotations after insertions. Rank, selection, predecessor, and successor all descend by comparing keys and subtree sizes. The returned checksum adds `step*(answer+1025)` for each query, using a one-based operation step; insertions contribute nothing. The independent reference maintains a sorted list directly.

The tree uses grandchild subtree sizes to decide rotations, which differs from the height-based AVL tree, randomized treap priorities, and splay-on-access policy in the catalog. The algorithm description is available in the [OI Wiki Size Balanced Tree article](https://oi-wiki.org/ds/sbt/). Only its algorithm ideas were used; code, prose, and examples are independently authored.

| Language | Port |
|---|---|
| C | [c/s/size_balanced_ordered_set.c](../../../c/s/size_balanced_ordered_set.c) |
| C3 | [c3/s/size_balanced_ordered_set.c3](../../../c3/s/size_balanced_ordered_set.c3) |
| C++ | [cpp/s/size_balanced_ordered_set.cpp](../../../cpp/s/size_balanced_ordered_set.cpp) |
| Elisa | [elisa/s/size_balanced_ordered_set.elisa](../../../elisa/s/size_balanced_ordered_set.elisa) |
| Mojo | [mojo/s/size_balanced_ordered_set.mojo](../../../mojo/s/size_balanced_ordered_set.mojo) |
| Nim | [nim/s/size_balanced_ordered_set.nim](../../../nim/s/size_balanced_ordered_set.nim) |
| Odin | [odin/s/size_balanced_ordered_set.odin](../../../odin/s/size_balanced_ordered_set.odin) |
| Rust | [rust/s/size_balanced_ordered_set.rs](../../../rust/s/size_balanced_ordered_set.rs) |
| V | [v/s/size_balanced_ordered_set.v](../../../v/s/size_balanced_ordered_set.v) |
| Zig | [zig/s/size_balanced_ordered_set.zig](../../../zig/s/size_balanced_ordered_set.zig) |
