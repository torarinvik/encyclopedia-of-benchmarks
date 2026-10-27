# First Fit Decreasing bin packing

This package implements the chapter's First Fit Decreasing variant: stably sort
items by nonincreasing size, then apply First Fit in that order. Equal-size
items retain their original input order as a deterministic tie refinement.

## Contract

ABI: `i64_array_bytes_output`; symbol:
`first_fit_decreasing_bin_packing`. Input is `[item_count,size_0,...]`, with
0–64 items sized as integer millionths of unit bin capacity (1–1,000,000).
The fixed-point grid removes floating-point fit ambiguity.

Output is `[bin_count,zero-based bin ID per original input item]` as
little-endian signed 64-bit words. Placement follows decreasing-size order, but
assignments are mapped back to original item order. Invalid input returns `-1`;
null or insufficient output storage returns `-2` without writes. Maximum input
is 65 words, output is 520 bytes, and fixed workspace is 1,024 bytes.

## Source and rights

Source: David S. Johnson, “Bin Packing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_49`](https://doi.org/10.1007/978-1-4939-2864-4_49),
section “First Fit Decreasing.” The chapter says to sort nonincreasingly before
applying First Fit; stable original-index ties are this profile's refinement.
The text is copyrighted by Springer and grants no source-code license; this
package is clean-room. See [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`first_fit_decreasing_bin_packing_oracle.py`](../../first_fit_decreasing_bin_packing_oracle.py).
Independent verifier: [`first_fit_decreasing_bin_packing_verifier_oracle.py`](../../first_fit_decreasing_bin_packing_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/f/first_fit_decreasing_bin_packing.c`](../../../c/f/first_fit_decreasing_bin_packing.c) |
| C3 | [`c3/f/first_fit_decreasing_bin_packing.c3`](../../../c3/f/first_fit_decreasing_bin_packing.c3) |
| C++ | [`cpp/f/first_fit_decreasing_bin_packing.cpp`](../../../cpp/f/first_fit_decreasing_bin_packing.cpp) |
| Elisa | [`elisa/f/first_fit_decreasing_bin_packing.elisa`](../../../elisa/f/first_fit_decreasing_bin_packing.elisa) |
| Nim | [`nim/f/first_fit_decreasing_bin_packing.nim`](../../../nim/f/first_fit_decreasing_bin_packing.nim) |
| Odin | [`odin/f/first_fit_decreasing_bin_packing.odin`](../../../odin/f/first_fit_decreasing_bin_packing.odin) |
| Rust | [`rust/f/first_fit_decreasing_bin_packing.rs`](../../../rust/f/first_fit_decreasing_bin_packing.rs) |
| V | [`v/f/first_fit_decreasing_bin_packing.v`](../../../v/f/first_fit_decreasing_bin_packing.v) |
| Zig | [`zig/f/first_fit_decreasing_bin_packing.zig`](../../../zig/f/first_fit_decreasing_bin_packing.zig) |
