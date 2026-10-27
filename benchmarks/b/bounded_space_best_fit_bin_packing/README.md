# Bounded-space Best Fit bin packing

This package implements the chapter's bounded-space Best Fit variant with two
open bins. For each arriving item it applies ordinary Best Fit among open
feasible bins, opening a new bin if none fit. After placement, it keeps the two
fullest partial bins open and permanently closes the others; full bins are
also closed. Equal residual spaces select the earliest global bin ID, while
equal partial loads retain the lower bin IDs. These tie rules make the source
description deterministic. The chapter's cited competitive ratio is not
claimed for this bounded fixture profile.

## Contract

ABI: `i64_array_bytes_output`; symbol:
`bounded_space_best_fit_bin_packing`. Input is
`[item_count,size_0,...]`, with 0–64 items sized as integer millionths of a
unit-capacity bin (1–1,000,000). Output is little-endian signed 64-bit
`[bin_count,zero-based bin ID per item in input order]`. Invalid input returns
`-1`; null or insufficient output storage returns `-2` without writes.
Maximum input is 65 words, output is 520 bytes, and fixed workspace is 1,536
bytes.

## Source and rights

Source: David S. Johnson, “Bin Packing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_49`](https://doi.org/10.1007/978-1-4939-2864-4_49),
section “Bounded-Space Algorithms.” The chapter describes a BF variant in
which all but the two fullest bins are closed. The after-placement timing and
tie rules above are deterministic refinements for this bounded profile. The
text is copyrighted by Springer and grants no source-code license; this
package is clean-room. See [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`bounded_space_best_fit_bin_packing_oracle.py`](../../bounded_space_best_fit_bin_packing_oracle.py).
Independent verifier: [`bounded_space_best_fit_bin_packing_verifier_oracle.py`](../../bounded_space_best_fit_bin_packing_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/b/bounded_space_best_fit_bin_packing.c`](../../../c/b/bounded_space_best_fit_bin_packing.c) |
| C3 | [`c3/b/bounded_space_best_fit_bin_packing.c3`](../../../c3/b/bounded_space_best_fit_bin_packing.c3) |
| C++ | [`cpp/b/bounded_space_best_fit_bin_packing.cpp`](../../../cpp/b/bounded_space_best_fit_bin_packing.cpp) |
| Elisa | [`elisa/b/bounded_space_best_fit_bin_packing.elisa`](../../../elisa/b/bounded_space_best_fit_bin_packing.elisa) |
| Nim | [`nim/b/bounded_space_best_fit_bin_packing.nim`](../../../nim/b/bounded_space_best_fit_bin_packing.nim) |
| Odin | [`odin/b/bounded_space_best_fit_bin_packing.odin`](../../../odin/b/bounded_space_best_fit_bin_packing.odin) |
| Rust | [`rust/b/bounded_space_best_fit_bin_packing.rs`](../../../rust/b/bounded_space_best_fit_bin_packing.rs) |
| V | [`v/b/bounded_space_best_fit_bin_packing.v`](../../../v/b/bounded_space_best_fit_bin_packing.v) |
| Zig | [`zig/b/bounded_space_best_fit_bin_packing.zig`](../../../zig/b/bounded_space_best_fit_bin_packing.zig) |
