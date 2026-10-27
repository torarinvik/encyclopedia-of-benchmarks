# Next Fit bin packing

This package implements the chapter's online Next Fit heuristic. It processes
items in input order and keeps only the current bin open: an item joins that bin
when it fits, otherwise a new bin is opened.

## Contract

ABI: `i64_array_bytes_output`; symbol: `next_fit_bin_packing`. Input is
`[item_count,size_0,...,size_(n-1)]`, where `item_count` is 0–64. Item sizes are
integer millionths of unit bin capacity, from 1 through 1,000,000. This fixed
rational grid removes floating-point fit ambiguity while preserving the
chapter's ordered online rule.

Output is `[bin_count,zero-based bin ID for each item in input order]` as
little-endian signed 64-bit words. The first item opens bin 0. Each later item
is placed in the most recently opened bin if it fits; otherwise it opens the
next bin. No earlier bin is reconsidered. Empty input returns one zero count
word. Invalid input returns `-1`; null or insufficient output storage returns
`-2` without writes. Maximum input is 65 words, output is 520 bytes, and fixed
workspace is 1,024 bytes.

The independent verifier partitions the input into maximal consecutive runs
whose total size fits in one bin, rather than using the port's running-load
simulation.

## Source and rights

Source: David S. Johnson, “Bin Packing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_49`](https://doi.org/10.1007/978-1-4939-2864-4_49),
section “Next Fit.” The chapter gives the ordered one-current-bin rule. The
chapter text is copyrighted by Springer and grants no source-code license; this
package is a clean-room implementation. See [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`next_fit_bin_packing_oracle.py`](../../next_fit_bin_packing_oracle.py).
Independent verifier: [`next_fit_bin_packing_verifier_oracle.py`](../../next_fit_bin_packing_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/n/next_fit_bin_packing.c`](../../../c/n/next_fit_bin_packing.c) |
| C3 | [`c3/n/next_fit_bin_packing.c3`](../../../c3/n/next_fit_bin_packing.c3) |
| C++ | [`cpp/n/next_fit_bin_packing.cpp`](../../../cpp/n/next_fit_bin_packing.cpp) |
| Elisa | [`elisa/n/next_fit_bin_packing.elisa`](../../../elisa/n/next_fit_bin_packing.elisa) |
| Nim | [`nim/n/next_fit_bin_packing.nim`](../../../nim/n/next_fit_bin_packing.nim) |
| Odin | [`odin/n/next_fit_bin_packing.odin`](../../../odin/n/next_fit_bin_packing.odin) |
| Rust | [`rust/n/next_fit_bin_packing.rs`](../../../rust/n/next_fit_bin_packing.rs) |
| V | [`v/n/next_fit_bin_packing.v`](../../../v/n/next_fit_bin_packing.v) |
| Zig | [`zig/n/next_fit_bin_packing.zig`](../../../zig/n/next_fit_bin_packing.zig) |
