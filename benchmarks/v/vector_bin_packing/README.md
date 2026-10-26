# Vector bin packing

This package implements the input-order generalized First Fit profile for
vector bin packing. Each item is a vector with one to four nonnegative resource
coordinates. The algorithm scans bins in creation order and places an item in
the first bin for which every coordinate remains within the unit capacity;
otherwise it opens a new bin. This is the deterministic multidimensional
First Fit rule, not a claim to implement every approximation algorithm surveyed
under the chapter title.

The input is `[n,d,vector[n*d]]`, with row-major item vectors, `1 <= n <= 32`,
`1 <= d <= 4`, and each coordinate in `[0,1000]`. Capacity is 1000 in every
dimension. The output is `[bin_count,assignment[n],loads[bin_count*d]]`, where
assignments are zero-based and loads are bin-major. Values use little-endian
signed 64-bit encoding. The largest result has `1 + 32 + 32*4 = 161` values
(1288 bytes). Invalid input returns `-1`; null output or insufficient capacity
returns `-2` without writing.

Source: “Vector Bin Packing,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_495`](https://doi.org/10.1007/978-1-4939-2864-4_495).
This is a clean-room profile based on the chapter's vector-item/unit-capacity
model and First Fit rule. No book prose or source code is copied.

## Ports

| Language | Port |
|---|---|
| C | `c/v/vector_bin_packing.c` |
| C3 | `c3/v/vector_bin_packing.c3` |
| C++ | `cpp/v/vector_bin_packing.cpp` |
| Elisa | `elisa/v/vector_bin_packing.elisa` |
| Nim | `nim/v/vector_bin_packing.nim` |
| Odin | `odin/v/vector_bin_packing.odin` |
| Rust | `rust/v/vector_bin_packing.rs` |
| V | `v/v/vector_bin_packing.v` |
| Zig | `zig/v/vector_bin_packing.zig` |

Primary exact-output oracle: `benchmarks/vector_bin_packing_oracle.py`.
Independent verifier oracle: `benchmarks/vector_bin_packing_verifier_oracle.py`.
