# Best Fit bin packing

This package implements the chapter's ordered Best Fit heuristic. For each
item, it chooses the currently open feasible bin that will have the least
remaining capacity after placement. Equal remaining capacities are resolved in
favor of the earliest bin. It opens a new bin only when no open bin fits.

## Contract

ABI: `i64_array_bytes_output`; symbol: `best_fit_bin_packing`. Input is
`[item_count,size_0,...,size_(n-1)]`, with `item_count` in 0–64. Each item size
is an integer number of millionths of unit bin capacity, 1–1,000,000. The
fixed-point grid avoids floating-point fit ambiguity. Items stay in input order;
this profile is not Best Fit Decreasing.

Output is `[bin_count,zero-based bin ID per input item]` as little-endian signed
64-bit words. Empty input emits a zero bin count. Invalid input returns `-1`;
null or insufficient output storage returns `-2` without writes. Maximum input
is 65 words, output is 520 bytes, and fixed workspace is 1,024 bytes.

The primary oracle simulates the remaining-space rule. The independent verifier
forms and orders the set of feasible `(remaining space, bin ID)` candidates for
each item.

## Source and rights

Source: David S. Johnson, “Bin Packing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_49`](https://doi.org/10.1007/978-1-4939-2864-4_49),
section “Best Fit.” The chapter specifies least leftover space and earliest-bin
tie-breaking. The text is copyrighted by Springer and grants no source-code
license; the ports are clean-room implementations. See [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`best_fit_bin_packing_oracle.py`](../../best_fit_bin_packing_oracle.py).
Independent verifier: [`best_fit_bin_packing_verifier_oracle.py`](../../best_fit_bin_packing_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/b/best_fit_bin_packing.c`](../../../c/b/best_fit_bin_packing.c) |
| C3 | [`c3/b/best_fit_bin_packing.c3`](../../../c3/b/best_fit_bin_packing.c3) |
| C++ | [`cpp/b/best_fit_bin_packing.cpp`](../../../cpp/b/best_fit_bin_packing.cpp) |
| Elisa | [`elisa/b/best_fit_bin_packing.elisa`](../../../elisa/b/best_fit_bin_packing.elisa) |
| Nim | [`nim/b/best_fit_bin_packing.nim`](../../../nim/b/best_fit_bin_packing.nim) |
| Odin | [`odin/b/best_fit_bin_packing.odin`](../../../odin/b/best_fit_bin_packing.odin) |
| Rust | [`rust/b/best_fit_bin_packing.rs`](../../../rust/b/best_fit_bin_packing.rs) |
| V | [`v/b/best_fit_bin_packing.v`](../../../v/b/best_fit_bin_packing.v) |
| Zig | [`zig/b/best_fit_bin_packing.zig`](../../../zig/b/best_fit_bin_packing.zig) |
