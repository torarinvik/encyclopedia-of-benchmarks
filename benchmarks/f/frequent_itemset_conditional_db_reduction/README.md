# Frequent-itemset conditional-database reduction

This package implements the one-prefix LCM database-reduction transform
described in Chapter 722. Given a frequent prefix `P`, it selects rows in
`Occ(P)`, removes items below `tail(P)` and one-item extensions below minimum
support, then merges equal reduced rows and records their multiplicity. It
benchmarks this conditional-database transform only; it does not enumerate
itemsets or implement the complete LCM miner.

## Contract

ABI: `i64_array_bytes_output`; symbol: `frequent_itemset_conditional_db_reduction`.
Input is `[item_count,row_count,minimum_support,tail,prefix_mask,transaction_masks...]`.
There are 1–8 items and 1–64 unit-weight transaction rows. Item `i` is bit `i`
of a transaction mask. The empty prefix uses `tail=-1,prefix_mask=0`; otherwise
`tail` must be the highest set item bit of the nonempty prefix. The prefix must
be frequent at the given threshold.

The transform first selects `Occ(P)`, computes support for every extension
item `i > tail(P)`, and retains those meeting `minimum_support`. It removes
items `i < tail(P)` and all infrequent extensions. As in the chapter's strict
inequality, the `tail(P)` bit itself remains in each row when `P` is nonempty.
Rows with identical reduced masks are coalesced into one record whose
multiplicity is their number of original rows. This profile uses unweighted
input rows; a reduced-row multiplicity is exactly a transaction count, and the
sum of output multiplicities equals `support(P)`.

Output is little-endian unsigned 64-bit words:
`[record_count,mask_0,multiplicity_0,...]`, with records sorted by ascending
reduced mask. Invalid input (including an infrequent prefix) returns `-1`;
null or insufficient output storage returns `-2` without writes. Maximum input
length is 69 words, maximum output is 1,032 bytes, and fixed workspace is
2,048 bytes.

The primary oracle follows the chapter's item-support filtering followed by a
single row reduction pass. The independent verifier computes each extension
support separately and constructs each reduced row independently before
counting duplicates.

## Source and rights

Source: Takeaki Uno, “Frequent Pattern Mining,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_722`](https://doi.org/10.1007/978-1-4939-2864-4_722),
section “Database Reduction.” The chapter describes removing items below the
prefix tail and items whose one-item extension is infrequent, then coalescing
identical conditional transactions with multiplicity. See [`RIGHTS.md`](RIGHTS.md)
for the clean-room and rights status.

Primary oracle: [`frequent_itemset_conditional_db_reduction_oracle.py`](../../frequent_itemset_conditional_db_reduction_oracle.py).
Independent verifier: [`frequent_itemset_conditional_db_reduction_verifier_oracle.py`](../../frequent_itemset_conditional_db_reduction_verifier_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`c/f/frequent_itemset_conditional_db_reduction.c`](../../../c/f/frequent_itemset_conditional_db_reduction.c) |
| C3 | [`c3/f/frequent_itemset_conditional_db_reduction.c3`](../../../c3/f/frequent_itemset_conditional_db_reduction.c3) |
| C++ | [`cpp/f/frequent_itemset_conditional_db_reduction.cpp`](../../../cpp/f/frequent_itemset_conditional_db_reduction.cpp) |
| Elisa | [`elisa/f/frequent_itemset_conditional_db_reduction.elisa`](../../../elisa/f/frequent_itemset_conditional_db_reduction.elisa) |
| Nim | [`nim/f/frequent_itemset_conditional_db_reduction.nim`](../../../nim/f/frequent_itemset_conditional_db_reduction.nim) |
| Odin | [`odin/f/frequent_itemset_conditional_db_reduction.odin`](../../../odin/f/frequent_itemset_conditional_db_reduction.odin) |
| Rust | [`rust/f/frequent_itemset_conditional_db_reduction.rs`](../../../rust/f/frequent_itemset_conditional_db_reduction.rs) |
| V | [`v/f/frequent_itemset_conditional_db_reduction.v`](../../../v/f/frequent_itemset_conditional_db_reduction.v) |
| Zig | [`zig/f/frequent_itemset_conditional_db_reduction.zig`](../../../zig/f/frequent_itemset_conditional_db_reduction.zig) |
