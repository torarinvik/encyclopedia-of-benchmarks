# Min-plus distance-matrix product

This bounded package implements the distance-matrix product defined in
Chapter 12, “All Pairs Shortest Paths via Matrix Multiplication.” For
`A` of shape `n×m` and `B` of shape `m×n`, it returns
`C[i,j] = min_k (A[i,k] + B[k,j])`, treating the sentinel `1_000_000` as
infinity. It covers one exact matrix product, a building block in the
chapter’s APSP methods.

## Contract

The ABI is `i64_array_bytes_output`, symbol `min_plus_distance_product`.
Input is `[n,m,A[n*m] row-major,B[m*n] row-major]`. Both dimensions are 1..8;
each entry is an integer in `0..1000` or the infinity sentinel. Finite sums
are at most 2000. The output is the row-major `n*n` result matrix using the
same sentinel when every candidate through `k` is infinite, serialized as
little-endian signed 64-bit values. Malformed input returns `-1` before
output checks. Null output or capacity below `8*n*n` bytes returns `-2`
without writes. Maximum input length is 130 words and maximum output is 512
bytes.

This package measures the distance-product operation only. It uses the
straightforward bounded min-plus loops and does not claim to implement the
chapter’s Romani fast-multiplication encoding, Zwick bridging-set selection,
witness recovery, or subcubic APSP running time.

## Source and rights

Based on Tadao Takaoka, “All Pairs Shortest Paths via Matrix Multiplication,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_12`](https://doi.org/10.1007/978-1-4939-2864-4_12).
The chapter defines ordinary, Boolean, and distance matrix products and
discusses their use in APSP. This package is an independent implementation of
the mathematical distance-product operation; it includes no copied book
text or code. See [`RIGHTS.md`](RIGHTS.md).

Workload fixtures are in [`workload.json`](workload.json); primary and
independent verifier oracles are
[`min_plus_distance_product_oracle.py`](../../min_plus_distance_product_oracle.py)
and [`min_plus_distance_product_verifier_oracle.py`](../../min_plus_distance_product_verifier_oracle.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/min_plus_distance_product.c`](../../../c/m/min_plus_distance_product.c) |
| C3 | [`c3/m/min_plus_distance_product.c3`](../../../c3/m/min_plus_distance_product.c3) |
| C++ | [`cpp/m/min_plus_distance_product.cpp`](../../../cpp/m/min_plus_distance_product.cpp) |
| Elisa | [`elisa/m/min_plus_distance_product.elisa`](../../../elisa/m/min_plus_distance_product.elisa) |
| Nim | [`nim/m/min_plus_distance_product.nim`](../../../nim/m/min_plus_distance_product.nim) |
| Odin | [`odin/m/min_plus_distance_product.odin`](../../../odin/m/min_plus_distance_product.odin) |
| Rust | [`rust/m/min_plus_distance_product.rs`](../../../rust/m/min_plus_distance_product.rs) |
| V | [`v/m/min_plus_distance_product.v`](../../../v/m/min_plus_distance_product.v) |
| Zig | [`zig/m/min_plus_distance_product.zig`](../../../zig/m/min_plus_distance_product.zig) |
