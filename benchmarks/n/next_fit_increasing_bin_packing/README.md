# Next Fit Increasing bin packing

This package implements the shared increasing-order heuristic identified in
“Bin Packing, Variants”: stable nondecreasing item-size order followed by Next
Fit. The chapter states that First Fit Increasing, Best Fit Increasing, and
Next Fit Increasing are the same algorithm for this ordering, so they map to
this one profile rather than three duplicate benchmarks.

## Contract

ABI: `i64_array_bytes_output`; symbol: `next_fit_increasing_bin_packing`.
Input is `[item_count,size_0,...,size_(n-1)]`, with `0 <= n <= 64`. Sizes are
integer millionths of unit bin capacity and must be in `[1,1_000_000]`. Equal
sizes retain their original order as a deterministic tie refinement.

The ports sort by nondecreasing size, then place each item into the current
last bin if it fits; otherwise they open a new bin. Assignments are returned
in original input order as little-endian signed-i64
`[bin_count,bin_ID_for_each_item]`, using zero-based IDs. The success result is
`8*(n+1)` bytes. Maximum input is 65 words, output is 520 bytes, and workspace
is 1,024 bytes. Empty input returns `[0]` in 8 bytes.

Malformed framing or sizes return `-1`; null output or insufficient capacity
returns `-2` without writes. The bounded profile reports assignments and
doesn't evaluate the GCBP concave bin-cost function or claim its approximation
ratio.

## Source and rights

Leah Epstein, “Bin Packing, Variants,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_491`](https://doi.org/10.1007/978-1-4939-2864-4_491),
Key Results. The chapter states that sorting in nondecreasing order gives the
same algorithm for First Fit Increasing, Best Fit Increasing, and Next Fit
Increasing. Stable equal-size ordering and fixed-point size encoding are
bounded-profile refinements.

The chapter and cited works are copyrighted; no source-code license is
asserted. These clean-room ports contain no copied source code or extended
prose. See [`RIGHTS.md`](RIGHTS.md).

Primary and independent verifier oracles:
[`next_fit_increasing_bin_packing_oracle.py`](../../next_fit_increasing_bin_packing_oracle.py) and
[`next_fit_increasing_bin_packing_verifier_oracle.py`](../../next_fit_increasing_bin_packing_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/n/next_fit_increasing_bin_packing.c`](../../../c/n/next_fit_increasing_bin_packing.c) |
| C3 | [`c3/n/next_fit_increasing_bin_packing.c3`](../../../c3/n/next_fit_increasing_bin_packing.c3) |
| C++ | [`cpp/n/next_fit_increasing_bin_packing.cpp`](../../../cpp/n/next_fit_increasing_bin_packing.cpp) |
| Elisa | [`elisa/n/next_fit_increasing_bin_packing.elisa`](../../../elisa/n/next_fit_increasing_bin_packing.elisa) |
| Nim | [`nim/n/next_fit_increasing_bin_packing.nim`](../../../nim/n/next_fit_increasing_bin_packing.nim) |
| Odin | [`odin/n/next_fit_increasing_bin_packing.odin`](../../../odin/n/next_fit_increasing_bin_packing.odin) |
| Rust | [`rust/n/next_fit_increasing_bin_packing.rs`](../../../rust/n/next_fit_increasing_bin_packing.rs) |
| V | [`v/n/next_fit_increasing_bin_packing.v`](../../../v/n/next_fit_increasing_bin_packing.v) |
| Zig | [`zig/n/next_fit_increasing_bin_packing.zig`](../../../zig/n/next_fit_increasing_bin_packing.zig) |
