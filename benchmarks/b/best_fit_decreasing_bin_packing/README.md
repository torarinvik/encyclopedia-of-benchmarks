# Best Fit Decreasing bin packing

This package implements the chapter's Best Fit Decreasing variant: stably sort
items by nonincreasing size, then choose for each item the feasible bin with
least remaining space. Equal-size items retain original input order as a
deterministic tie refinement; equal post-placement bin remainders choose the
earliest bin.

## Contract

ABI: `i64_array_bytes_output`; symbol:
`best_fit_decreasing_bin_packing`. Input is `[item_count,size_0,...]`, with
0–64 items sized as integer millionths of unit bin capacity (1–1,000,000).
Output is `[bin_count,zero-based bin ID per original input item]` as
little-endian signed 64-bit words. Placement follows decreasing-size order,
while assignments are mapped back to the original order. Invalid input returns
`-1`; null or insufficient output storage returns `-2` without writes. Maximum
input is 65 words, output is 520 bytes, and fixed workspace is 1,024 bytes.

## Source and rights

Source: David S. Johnson, “Bin Packing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_49`](https://doi.org/10.1007/978-1-4939-2864-4_49),
section “Best Fit Decreasing.” The chapter says to sort nonincreasingly before
applying Best Fit; stable original-index ties are this profile's refinement.
The text is copyrighted by Springer and grants no source-code license; this
package is clean-room. See [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`best_fit_decreasing_bin_packing_oracle.py`](../../best_fit_decreasing_bin_packing_oracle.py).
Independent verifier: [`best_fit_decreasing_bin_packing_verifier_oracle.py`](../../best_fit_decreasing_bin_packing_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/b/best_fit_decreasing_bin_packing.c`](../../../c/b/best_fit_decreasing_bin_packing.c) |
| C3 | [`c3/b/best_fit_decreasing_bin_packing.c3`](../../../c3/b/best_fit_decreasing_bin_packing.c3) |
| C++ | [`cpp/b/best_fit_decreasing_bin_packing.cpp`](../../../cpp/b/best_fit_decreasing_bin_packing.cpp) |
| Elisa | [`elisa/b/best_fit_decreasing_bin_packing.elisa`](../../../elisa/b/best_fit_decreasing_bin_packing.elisa) |
| Nim | [`nim/b/best_fit_decreasing_bin_packing.nim`](../../../nim/b/best_fit_decreasing_bin_packing.nim) |
| Odin | [`odin/b/best_fit_decreasing_bin_packing.odin`](../../../odin/b/best_fit_decreasing_bin_packing.odin) |
| Rust | [`rust/b/best_fit_decreasing_bin_packing.rs`](../../../rust/b/best_fit_decreasing_bin_packing.rs) |
| V | [`v/b/best_fit_decreasing_bin_packing.v`](../../../v/b/best_fit_decreasing_bin_packing.v) |
| Zig | [`zig/b/best_fit_decreasing_bin_packing.zig`](../../../zig/b/best_fit_decreasing_bin_packing.zig) |
