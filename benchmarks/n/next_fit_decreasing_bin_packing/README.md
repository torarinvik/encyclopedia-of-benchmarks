# Next Fit Decreasing bin packing

This package implements the chapter's Next Fit Decreasing (NFD) assignment
rule: order items by nonincreasing size, then apply Next Fit to that sequence.
It is distinct from [`next_fit_bin_packing`](../next_fit_bin_packing/README.md),
which consumes the caller's original order, and from First Fit Decreasing or
Best Fit Decreasing, which use different placement rules.

## Contract

ABI: `i64_array_bytes_output`; symbol: `next_fit_decreasing_bin_packing`.
Input is `[item_count,size_0,...,size_(n-1)]`, with `0 <= n <= 64`. Sizes are
integer millionths of unit bin capacity and must be in `[1,1_000_000]`; this
fixed-point grid avoids floating-point fit ambiguity. Equal-size items retain
their input order as a deterministic refinement of the nonincreasing sort.

NFD packs each sorted item into the current last bin if it fits; otherwise it
opens a new bin. The returned assignment is mapped back to original item order.
Output is little-endian signed-i64 `[bin_count,bin_ID_for_each_input_item]`,
with zero-based bin IDs. A valid call returns `8*(n+1)` bytes; the maximum input
is 65 words, maximum output is 520 bytes, and declared workspace is 1,024
bytes. Empty input returns the 8-byte word `[0]`.

Malformed framing or sizes return `-1`. A null output pointer or insufficient
capacity returns `-2` without writes. The bounded profile returns the packing
assignment; it does not accept/evaluate the GCBP concave bin-cost function or
claim the chapter's approximation guarantee for any particular cost model.

## Source and rights

Leah Epstein, “Bin Packing, Variants,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_491`](https://doi.org/10.1007/978-1-4939-2864-4_491),
Key Results. The chapter states that Next Fit Decreasing sorts the item list
nonincreasingly before applying Next Fit. The stable tie rule and integer-size
encoding are bounded-profile refinements.

The chapter and cited works are copyrighted; no source-code license is
asserted. These ports are clean-room implementations with no copied source
code or extended prose. See [`RIGHTS.md`](RIGHTS.md).

Primary and independent verifier oracles:
[`next_fit_decreasing_bin_packing_oracle.py`](../../next_fit_decreasing_bin_packing_oracle.py) and
[`next_fit_decreasing_bin_packing_verifier_oracle.py`](../../next_fit_decreasing_bin_packing_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/n/next_fit_decreasing_bin_packing.c`](../../../c/n/next_fit_decreasing_bin_packing.c) |
| C3 | [`c3/n/next_fit_decreasing_bin_packing.c3`](../../../c3/n/next_fit_decreasing_bin_packing.c3) |
| C++ | [`cpp/n/next_fit_decreasing_bin_packing.cpp`](../../../cpp/n/next_fit_decreasing_bin_packing.cpp) |
| Elisa | [`elisa/n/next_fit_decreasing_bin_packing.elisa`](../../../elisa/n/next_fit_decreasing_bin_packing.elisa) |
| Nim | [`nim/n/next_fit_decreasing_bin_packing.nim`](../../../nim/n/next_fit_decreasing_bin_packing.nim) |
| Odin | [`odin/n/next_fit_decreasing_bin_packing.odin`](../../../odin/n/next_fit_decreasing_bin_packing.odin) |
| Rust | [`rust/n/next_fit_decreasing_bin_packing.rs`](../../../rust/n/next_fit_decreasing_bin_packing.rs) |
| V | [`v/n/next_fit_decreasing_bin_packing.v`](../../../v/n/next_fit_decreasing_bin_packing.v) |
| Zig | [`zig/n/next_fit_decreasing_bin_packing.zig`](../../../zig/n/next_fit_decreasing_bin_packing.zig) |
