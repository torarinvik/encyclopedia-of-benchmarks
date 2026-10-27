# Frequent itemset occurrence delivery

This package implements the chapter's one-pass Delivery operation for a single
frequent-itemset prefix. It scans rows containing the prefix once and sends each
row to every eligible one-item extension it contains. The result records each
extension's occurrence-row set and support. The support threshold applies the
chapter's monotone-property pruning after delivery; this is one level of the
enumeration, not a full frequent-itemset miner.

## Contract

ABI: `i64_array_bytes_output`; symbol: `frequent_itemset_delivery`. Input is
`[item_count,transaction_count,minimum_support,tail,prefix_mask,transaction_masks...]`.
There are 1–8 items and 1–64 transaction rows. Item `i` is bit `i` of a
transaction mask. The empty prefix uses `tail=-1,prefix_mask=0`; otherwise the
tail is the highest set bit in the prefix. The prefix must be contained in a
transaction for that row to participate. Rows are distinct occurrences even
when their masks are equal. The minimum support is in `[1,transaction_count]`.

Output is little-endian unsigned 64-bit words:
`[record_count,item_id,occurrence_row_mask,support,...]`. Records are sorted by
ascending extension item ID and include only extensions meeting minimum
support. Bit `r` of `occurrence_row_mask` is set exactly when transaction row
`r` contains both the prefix and the extension item. Invalid input returns
`-1`; null or insufficient output storage returns `-2` without writes. Maximum
input length is 69 words, maximum output is 200 bytes, and fixed workspace is
512 bytes.

The primary oracle follows the row-at-a-time delivery sweep. The independent
verifier forms every child occurrence set separately by containment tests.
Neither oracle calls the benchmark ports.

## Source and rights

Source: Takeaki Uno, “Frequent Pattern Mining,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_722`](https://doi.org/10.1007/978-1-4939-2864-4_722),
section “Delivery,” steps 1–4. The chapter describes computing all
`Occ(P ∪ {i})` sets for `i > tail(P)` by one scan of `Occ(P)`. This implementation
is a clean-room bounded profile; the chapter supplies no source-code license.
See [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`frequent_itemset_delivery_oracle.py`](../../frequent_itemset_delivery_oracle.py).
Independent verifier: [`frequent_itemset_delivery_verifier_oracle.py`](../../frequent_itemset_delivery_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/f/frequent_itemset_delivery.c`](../../../c/f/frequent_itemset_delivery.c) |
| C3 | [`c3/f/frequent_itemset_delivery.c3`](../../../c3/f/frequent_itemset_delivery.c3) |
| C++ | [`cpp/f/frequent_itemset_delivery.cpp`](../../../cpp/f/frequent_itemset_delivery.cpp) |
| Elisa | [`elisa/f/frequent_itemset_delivery.elisa`](../../../elisa/f/frequent_itemset_delivery.elisa) |
| Nim | [`nim/f/frequent_itemset_delivery.nim`](../../../nim/f/frequent_itemset_delivery.nim) |
| Odin | [`odin/f/frequent_itemset_delivery.odin`](../../../odin/f/frequent_itemset_delivery.odin) |
| Rust | [`rust/f/frequent_itemset_delivery.rs`](../../../rust/f/frequent_itemset_delivery.rs) |
| V | [`v/f/frequent_itemset_delivery.v`](../../../v/f/frequent_itemset_delivery.v) |
| Zig | [`zig/f/frequent_itemset_delivery.zig`](../../../zig/f/frequent_itemset_delivery.zig) |
