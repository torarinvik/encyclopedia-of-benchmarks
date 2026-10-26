# First Fit bin packing

This package implements the ordered First Fit rule described in “First Fit Algorithm for Bin Packing,” *Encyclopedia of Algorithms* (DOI [10.1007/978-1-4939-2864-4_487](https://doi.org/10.1007/978-1-4939-2864-4_487)): process items in the supplied order and place each into the lowest-indexed already-open bin with enough remaining capacity; open a new bin only when none fits.

## Contract

The `i64_array_bytes_output` frame is `[item_count, size_0, ..., size_(n-1)]`. `item_count` is 0–64. Each item size is an integer number of millionths of unit capacity, from 1 to 1,000,000 inclusive. This common-grid domain represents a bounded subset of the chapter’s rational item sizes and avoids floating-point fit ambiguity. Items are never reordered; this is First Fit, not First Fit Decreasing or Best Fit.

Output is `[bin_count, bin_for_item_0, ..., bin_for_item_(n-1)]`, as little-endian signed-i64 values. Bin IDs are zero-based and assignments follow input order. The return value is output bytes; malformed input returns `-1`; a short or null output pointer returns `-2`. The entire frame is validated before capacity is checked and no output is written on either error. Empty input returns one zero bin-count value.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/first_fit_bin_packing.c`](../../../c/f/first_fit_bin_packing.c) |
| C3 | [`c3/f/first_fit_bin_packing.c3`](../../../c3/f/first_fit_bin_packing.c3) |
| C++ | [`cpp/f/first_fit_bin_packing.cpp`](../../../cpp/f/first_fit_bin_packing.cpp) |
| Elisa | [`elisa/f/first_fit_bin_packing.elisa`](../../../elisa/f/first_fit_bin_packing.elisa) |
| Nim | [`nim/f/first_fit_bin_packing.nim`](../../../nim/f/first_fit_bin_packing.nim) |
| Odin | [`odin/f/first_fit_bin_packing.odin`](../../../odin/f/first_fit_bin_packing.odin) |
| Rust | [`rust/f/first_fit_bin_packing.rs`](../../../rust/f/first_fit_bin_packing.rs) |
| V | [`v/f/first_fit_bin_packing.v`](../../../v/f/first_fit_bin_packing.v) |
| Zig | [`zig/f/first_fit_bin_packing.zig`](../../../zig/f/first_fit_bin_packing.zig) |

The primary oracle is [`first_fit_bin_packing_oracle.py`](../../first_fit_bin_packing_oracle.py); the verifier independently simulates bins in [`first_fit_bin_packing_verifier_oracle.py`](../../first_fit_bin_packing_verifier_oracle.py).

## Attribution and rights

The algorithm is attributed to György Dósa, “First Fit Algorithm for Bin Packing,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_487. The Springer chapter is used only to identify the rule and its ordering semantics. No book prose, figures, or code are reproduced; all package code is independently written. This attribution does not grant rights to redistribute the book.
