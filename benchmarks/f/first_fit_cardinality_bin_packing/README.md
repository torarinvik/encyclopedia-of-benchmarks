# First-fit bin packing with a cardinality limit

This profile applies first-fit to online bin packing with a maximum number of items per bin. For each item in input order, scan bins in creation order and place it in the first bin that has both remaining capacity and an unused item slot. If no existing bin satisfies both conditions, open a new bin. Every valid item is placed; no item is rejected.

Input is `[n,max_items,capacity,sizes...]`, with `1<=n<=32`, `1<=max_items<=32`, `1<=capacity<=10,000`, and each item size in `1..capacity`. Output is `[bin_count,bin_id_for_each_item...]` as little-endian signed 64-bit values. The result is bounded by 33 words (264 bytes). Invalid input returns `-1`; null or short output returns `-2` without writes.

The per-bin count condition changes the placement feasibility test, so this is distinct from ordinary [`first_fit_bin_packing`](../first_fit_bin_packing/README.md), which only checks capacity. This profile instantiates the First-Fit adaptation discussed in the chapter; it does not implement the chapter’s asymptotic approximation schemes or all cardinality-constrained variants.

## Implementations

| Language | Source |
|---|---|
| C | [`c/f/first_fit_cardinality_bin_packing.c`](../../../c/f/first_fit_cardinality_bin_packing.c) |
| C3 | [`c3/f/first_fit_cardinality_bin_packing.c3`](../../../c3/f/first_fit_cardinality_bin_packing.c3) |
| C++ | [`cpp/f/first_fit_cardinality_bin_packing.cpp`](../../../cpp/f/first_fit_cardinality_bin_packing.cpp) |
| Elisa | [`elisa/f/first_fit_cardinality_bin_packing.elisa`](../../../elisa/f/first_fit_cardinality_bin_packing.elisa) |
| Nim | [`nim/f/first_fit_cardinality_bin_packing.nim`](../../../nim/f/first_fit_cardinality_bin_packing.nim) |
| Odin | [`odin/f/first_fit_cardinality_bin_packing.odin`](../../../odin/f/first_fit_cardinality_bin_packing.odin) |
| Rust | [`rust/f/first_fit_cardinality_bin_packing.rs`](../../../rust/f/first_fit_cardinality_bin_packing.rs) |
| V | [`v/f/first_fit_cardinality_bin_packing.v`](../../../v/f/first_fit_cardinality_bin_packing.v) |
| Zig | [`zig/f/first_fit_cardinality_bin_packing.zig`](../../../zig/f/first_fit_cardinality_bin_packing.zig) |

Primary oracle: [`first_fit_cardinality_bin_packing_oracle.py`](../../first_fit_cardinality_bin_packing_oracle.py). Independent verifier oracle: [`first_fit_cardinality_bin_packing_verifier_oracle.py`](../../first_fit_cardinality_bin_packing_verifier_oracle.py).

## Attribution and rights

Based on the First-Fit adaptation described in “Bin Packing with Cardinality Constraints,” *Encyclopedia of Algorithms* (2016), DOI [10.1007/978-1-4939-2864-4_489](https://doi.org/10.1007/978-1-4939-2864-4_489). Implementations are independently written, and no book prose, code, or figures are reproduced. The book remains copyrighted by Springer; attribution does not grant redistribution rights to its contents.
