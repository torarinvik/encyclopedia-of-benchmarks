# LCM prefix-preserving closed-itemset enumeration

This package implements LCM's complete depth-first enumeration of frequent
closed itemsets using prefix-preserving closure (ppc) extensions. It follows
the paper's core-index and ppc-child rule, rather than listing all frequent
itemsets and filtering them afterward.

## Contract

The `i64_array_bytes_output` input is
`[item_count,row_count,minimum_support,transaction_mask...]`. There are 1–8
items and 1–16 rows. Item IDs are zero-based and item `i` is bit `i` of each
mask. Rows with identical masks remain separate transaction occurrences. The
minimum support lies in `[1,row_count]`.

The output is little-endian signed 64-bit words:
`[record_count,mask_0,support_0,...]`. It includes every frequent closed
itemset, including the closure of the empty set, in ppc preorder depth-first
order. Candidate item IDs are visited ascending at each node. The root is the
intersection of all transaction masks, because that is `closure(empty)`; its
core index is the sentinel `-1` so all absent item IDs can be considered.
For any non-root closed mask `P`, the core index is the lowest item `i` for
which `support(P restricted to bits 0..i) == support(P)`. For each absent
item `i` greater than the core, form `Q=closure(P∪{i})`; recurse exactly when
`Q` is frequent and `P` and `Q` agree on all bits below `i`. The closure is
the intersection of all rows containing the mask.

Malformed input returns `-1`; null output or insufficient capacity returns
`-2` without writing. The largest valid input is 19 words. At most `2^8`
closed masks can be returned, so the maximum output is 4,104 bytes. The
bounded output staging plus traversal workspace is capped at 8 KiB.

## Duplicate decision

The local [`frequent_itemset_backtrack`](../../f/frequent_itemset_backtrack/README.md)
enumerates all frequent itemsets with ordinary tail extension and
down-projection. [`frequent_pattern_growth`](../../f/frequent_pattern_growth/README.md)
uses conditional FP-tree growth but returns only a count. The
[`frequent_itemset_delivery`](../../f/frequent_itemset_delivery/README.md) and
[`frequent_itemset_conditional_db_reduction`](../../f/frequent_itemset_conditional_db_reduction/README.md)
packages expose one-prefix primitives, not a complete closed-itemset search.
None implements the ppc parent rule and unique-parent DFS used here, so this
is a distinct algorithm contract.

## Source and provenance

The book entry is Takeaki Uno, “Frequent Pattern Mining,” *Encyclopedia of
Algorithms*, Chapter 722, DOI
[10.1007/978-1-4939-2864-4_722](https://doi.org/10.1007/978-1-4939-2864-4_722).
The operational procedure is described by Takeaki Uno, Tatsuya Asai, Yuzo
Uchida, and Hiroki Arimura, “An Efficient Algorithm for Enumerating Closed
Patterns in Transaction Databases,” Sections 2 and 4.3, DOI
[10.1137/S0097539794275872](https://doi.org/10.1137/S0097539794275872),
especially the core-index / ppc-extension definition and Algorithm LCM in
Figure 3. The paper's Figure 7 adds occurrence delivery and conditional
database reduction as optimizations; this bounded profile uses direct row
scans for closure and support. The algorithms are independently implemented;
no book or paper code, protected text, or figures are reproduced. See
[`RIGHTS.md`](RIGHTS.md).

The primary reference is [`primary_oracle.py`](primary_oracle.py). The
independent exhaustive reference is [`independent_oracle.py`](independent_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/l/lcm_ppc_closed_itemset_enumeration.c`](../../../c/l/lcm_ppc_closed_itemset_enumeration.c) |
| C3 | [`c3/l/lcm_ppc_closed_itemset_enumeration.c3`](../../../c3/l/lcm_ppc_closed_itemset_enumeration.c3) |
| C++ | [`cpp/l/lcm_ppc_closed_itemset_enumeration.cpp`](../../../cpp/l/lcm_ppc_closed_itemset_enumeration.cpp) |
| Elisa | [`elisa/l/lcm_ppc_closed_itemset_enumeration.elisa`](../../../elisa/l/lcm_ppc_closed_itemset_enumeration.elisa) |
| Mojo | [`mojo/l/lcm_ppc_closed_itemset_enumeration.mojo`](../../../mojo/l/lcm_ppc_closed_itemset_enumeration.mojo) |
| Nim | [`nim/l/lcm_ppc_closed_itemset_enumeration.nim`](../../../nim/l/lcm_ppc_closed_itemset_enumeration.nim) |
| Odin | [`odin/l/lcm_ppc_closed_itemset_enumeration.odin`](../../../odin/l/lcm_ppc_closed_itemset_enumeration.odin) |
| Rust | [`rust/l/lcm_ppc_closed_itemset_enumeration.rs`](../../../rust/l/lcm_ppc_closed_itemset_enumeration.rs) |
| V | [`v/l/lcm_ppc_closed_itemset_enumeration.v`](../../../v/l/lcm_ppc_closed_itemset_enumeration.v) |
| Zig | [`zig/l/lcm_ppc_closed_itemset_enumeration.zig`](../../../zig/l/lcm_ppc_closed_itemset_enumeration.zig) |
