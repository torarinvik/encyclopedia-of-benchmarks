# Frequent itemset enumeration by Backtrack

This bounded profile implements the deterministic Backtrack method described
in Chapter 722. It grows a frequent itemset depth-first by adding only items
greater than the current tail. Each child call receives only transactions
containing the newly added item (down projection). Infrequent children are
pruned by the support threshold. The empty set is the recursion root and is
not included in output.

## Contract

The `i64_array_bytes_output` input is
`[item_count,transaction_count,minimum_support,transaction_mask...]`. Item
indices are 0 through `item_count-1`, represented by the corresponding bits.
There are 1–8 items and 1–16 transaction rows; duplicate transactions are
allowed. The output is little-endian signed 64-bit words:
`[record_count,mask_0,support_0,...]`. Records are emitted in ascending-item
depth-first tail-extension order, with each parent before its extensions.
Malformed input returns `-1`; null or short output returns `-2` without
writing. The maximum valid input is 19 words and the maximum output is 4,088
bytes (all 255 nonempty subsets are frequent).

This is distinct from [`frequent_pattern_growth`](../frequent_pattern_growth/README.md),
which grows weighted conditional FP-tree paths and returns only a count. This
package enumerates the masks and supports using the Backtrack tail-extension
and down-projection traversal.

## Source attribution and rights

Based on Takeaki Uno, “Frequent Pattern Mining,” *Encyclopedia of Algorithms*,
DOI [10.1007/978-1-4939-2864-4_722](https://doi.org/10.1007/978-1-4939-2864-4_722).
The algorithm is independently implemented from the chapter’s description;
no book code, prose, or figures are reproduced. The book is copyrighted by
Springer; this attribution does not grant rights to redistribute its contents.

The primary oracle is
[`frequent_itemset_backtrack_oracle.py`](../../frequent_itemset_backtrack_oracle.py).
The independent verifier oracle is
[`frequent_itemset_backtrack_verifier_oracle.py`](../../frequent_itemset_backtrack_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/f/frequent_itemset_backtrack.c`](../../../c/f/frequent_itemset_backtrack.c) |
| C3 | [`c3/f/frequent_itemset_backtrack.c3`](../../../c3/f/frequent_itemset_backtrack.c3) |
| C++ | [`cpp/f/frequent_itemset_backtrack.cpp`](../../../cpp/f/frequent_itemset_backtrack.cpp) |
| Elisa | [`elisa/f/frequent_itemset_backtrack.elisa`](../../../elisa/f/frequent_itemset_backtrack.elisa) |
| Nim | [`nim/f/frequent_itemset_backtrack.nim`](../../../nim/f/frequent_itemset_backtrack.nim) |
| Odin | [`odin/f/frequent_itemset_backtrack.odin`](../../../odin/f/frequent_itemset_backtrack.odin) |
| Rust | [`rust/f/frequent_itemset_backtrack.rs`](../../../rust/f/frequent_itemset_backtrack.rs) |
| V | [`v/f/frequent_itemset_backtrack.v`](../../../v/f/frequent_itemset_backtrack.v) |
| Zig | [`zig/f/frequent_itemset_backtrack.zig`](../../../zig/f/frequent_itemset_backtrack.zig) |
