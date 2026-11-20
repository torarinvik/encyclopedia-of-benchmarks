# Randomized BST order statistics with split and join

This profile applies a bounded operation trace to a Martínez–Roura randomized
binary search tree (RBST). It measures subtree-size based insertion and join,
one-based rank selection, key partitioning, and ordered structural join. The
tree stores subtree cardinalities and uses random choices derived from those
cardinalities; it does not store treap priorities. This distinguishes it from
[`treap_unique_key_set`](../../t/treap_unique_key_set/README.md), whose
priorities are deterministic and whose profile exposes only final-set
behavior, and from
[`ordered_set_avl_order_statistics`](../../o/ordered_set_avl_order_statistics/README.md),
which uses AVL rotations and does not expose structural split/join.

## Contract

The exported scalar symbol is
`randomized_binary_search_tree_order_statistics_split_join`. Input is
`[N,Q,seed,initial[N],(opcode,a,b,c)*Q]`:

- `0<=N,Q<=32`; the seed is an unsigned 32-bit value encoded as i64.
- Initial keys are strictly increasing in `0..1000`. They are inserted into
  tree 0 in input order; tree 1 starts empty. At most 64 nodes can be live.
- Keys are unique. Insert and erase of an already-present or absent key are
  no-ops. Tree IDs are 0 and 1.
- Opcode `0` is `(0,tree,key,0)`: insert `key` if absent.
- Opcode `1` is `(1,tree,key,0)`: erase `key` if present.
- Opcode `2` is `(2,tree,k,0)`: query the one-based `k`th smallest key. `k`
  must be in `1..65`; a rank beyond the current size answers `-1`.
- Opcode `3` is `(3,source,destination,pivot)`: keep keys `<pivot` in source
  and move keys `>=pivot` to destination. The IDs must differ and destination
  must be empty. `pivot` is in `0..1001`.
- Opcode `4` is `(4,left,right,0)`: concatenate the ordered sets into left and
  clear right. IDs must differ and every left key must be smaller than every
  right key. Empty-tree joins are allowed; the ordering condition holds
  vacuously and the nonempty tree is transferred or preserved without a random
  draw.
- For kth-query answers in query order, return
  `sum(query_index*(answer+1))`, where `query_index` is one-based. Thus an
  out-of-range rank contributes zero. The maximum valid result is `528528`.
- Malformed frames and state-invalid split/join traces return `-1`. The exact
  valid input length is `3+N+4*Q`; maximum valid and parseable lengths are 163
  and 164 signed 64-bit words. Workspace is 8192 bytes.

The primary ports use the Martínez–Roura size-based insertion and join rules.
Subtree-size selection provides kth queries; split is the recursive BST
partition at the pivot. A specified 32-bit LCG makes shapes replayable across
languages: each raw draw first advances `state = (1664525*state +
1013904223) mod 2^32` and returns the new state. `randbelow(bound)` requires a
positive bound, rejects values below `2^32 mod bound`, and returns the
accepted value modulo `bound`. State advances on rejected draws as well.
Duplicate inserts consume no random draws. The independent reference models
the same operation trace with two sorted lists and uses no tree or random
choices.

## Sources and provenance

- Martínez and Roura,
  [“Randomized Binary Search Trees”](https://doi.org/10.1145/274787.274812),
  *Journal of the ACM* 45(2), 288–323 (1998), is the primary method source.
- Eberl,
  [“Randomised Binary Search Trees”](https://isa-afp.org/entries/Randomised_BSTs.html),
  Archive of Formal Proofs, formalizes and proves properties of the
  Martínez–Roura structure, including partition and join.
- The [Suisen Java library README](https://github.com/suisen-cp/java_competitive_programming_library)
  was used only to discover the `LongOrderedMap` operation family. No source
  code, documentation prose, tests, or fixtures were copied.

All ports, references, and fixtures here are clean-room. See
[`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), and
[`INVENTORY.md`](INVENTORY.md). The static inventory helper
[`check_inventory.py`](check_inventory.py) has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/randomized_binary_search_tree_order_statistics_split_join.c`](../../../c/r/randomized_binary_search_tree_order_statistics_split_join.c) |
| C3 | [`c3/r/randomized_binary_search_tree_order_statistics_split_join.c3`](../../../c3/r/randomized_binary_search_tree_order_statistics_split_join.c3) |
| C++ | [`cpp/r/randomized_binary_search_tree_order_statistics_split_join.cpp`](../../../cpp/r/randomized_binary_search_tree_order_statistics_split_join.cpp) |
| Elisa | [`elisa/r/randomized_binary_search_tree_order_statistics_split_join.elisa`](../../../elisa/r/randomized_binary_search_tree_order_statistics_split_join.elisa) |
| Mojo | [`mojo/r/randomized_binary_search_tree_order_statistics_split_join.mojo`](../../../mojo/r/randomized_binary_search_tree_order_statistics_split_join.mojo) |
| Nim | [`nim/r/randomized_binary_search_tree_order_statistics_split_join.nim`](../../../nim/r/randomized_binary_search_tree_order_statistics_split_join.nim) |
| Odin | [`odin/r/randomized_binary_search_tree_order_statistics_split_join.odin`](../../../odin/r/randomized_binary_search_tree_order_statistics_split_join.odin) |
| Rust | [`rust/r/randomized_binary_search_tree_order_statistics_split_join.rs`](../../../rust/r/randomized_binary_search_tree_order_statistics_split_join.rs) |
| V | [`v/r/randomized_binary_search_tree_order_statistics_split_join.v`](../../../v/r/randomized_binary_search_tree_order_statistics_split_join.v) |
| Zig | [`zig/r/randomized_binary_search_tree_order_statistics_split_join.zig`](../../../zig/r/randomized_binary_search_tree_order_statistics_split_join.zig) |
