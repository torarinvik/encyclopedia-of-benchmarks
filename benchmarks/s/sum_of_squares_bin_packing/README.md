# Sum-of-Squares bin packing

This package implements the chapter's online Sum-of-Squares placement rule for
one bounded integer-scaled instance. For every item, it chooses the feasible
existing bin or a new bin that minimizes the resulting
`sum(n_h * n_h)` over partial loads `h = 1..capacity-1`, where `n_h` counts
bins currently holding total size `h`. Full bins do not contribute. Ties keep
the lowest existing bin ID; a new bin is selected only when its score is
strictly lower. This is a deterministic tie refinement to the chapter rule.

## Contract

ABI: `i64_array_bytes_output`; symbol: `sum_of_squares_bin_packing`. Input is
`[capacity,item_count,size_0,...]`, with capacity 1–64 and 0–64 item sizes in
`1..capacity`. Output is little-endian signed 64-bit
`[bin_count,zero-based bin ID per item in input order]`. Invalid input returns
`-1`; null or insufficient output storage returns `-2` without writes.
Maximum input is 66 words, output is 520 bytes, and fixed workspace is 2,048
bytes. The empty instance returns one zero word.

## Source and rights

Source: David S. Johnson, “Bin Packing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_49`](https://doi.org/10.1007/978-1-4939-2864-4_49),
section “Sum-of-Squares.” The chapter states the objective over partial-bin
occupancy counts and describes placing each arriving item to minimize its
resulting value. The text is copyrighted by Springer and grants no source-code
license. This package is independently written and does not copy book prose,
code, or figures; see [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`sum_of_squares_bin_packing_oracle.py`](../../sum_of_squares_bin_packing_oracle.py).
Independent verifier: [`sum_of_squares_bin_packing_verifier_oracle.py`](../../sum_of_squares_bin_packing_verifier_oracle.py).

## Ports

| Language | Source |
|---|---|
| C | [`c/s/sum_of_squares_bin_packing.c`](../../../c/s/sum_of_squares_bin_packing.c) |
| C3 | [`c3/s/sum_of_squares_bin_packing.c3`](../../../c3/s/sum_of_squares_bin_packing.c3) |
| C++ | [`cpp/s/sum_of_squares_bin_packing.cpp`](../../../cpp/s/sum_of_squares_bin_packing.cpp) |
| Elisa | [`elisa/s/sum_of_squares_bin_packing.elisa`](../../../elisa/s/sum_of_squares_bin_packing.elisa) |
| Nim | [`nim/s/sum_of_squares_bin_packing.nim`](../../../nim/s/sum_of_squares_bin_packing.nim) |
| Odin | [`odin/s/sum_of_squares_bin_packing.odin`](../../../odin/s/sum_of_squares_bin_packing.odin) |
| Rust | [`rust/s/sum_of_squares_bin_packing.rs`](../../../rust/s/sum_of_squares_bin_packing.rs) |
| V | [`v/s/sum_of_squares_bin_packing.v`](../../../v/s/sum_of_squares_bin_packing.v) |
| Zig | [`zig/s/sum_of_squares_bin_packing.zig`](../../../zig/s/sum_of_squares_bin_packing.zig) |
