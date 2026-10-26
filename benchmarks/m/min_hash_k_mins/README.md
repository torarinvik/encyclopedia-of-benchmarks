# k-mins MinHash sketch

This bounded deterministic projection implements the chapter's `k-mins`
MinHash structure: for each of `k` independent rank assignments, retain the
item with the smallest rank. Random ranks are supplied as fixture inputs, so
the benchmark covers the exact order-statistic and tie behavior without
claiming a random hash distribution.

Input is `[n,k, rank_0_0,...,rank_(n-1)_(k-1)]` in row-major order, with
`1<=n<=16`, `1<=k<=4`, and ranks in `[0,1000]`. Output is the selected item ID
for each rank function, in function order; equal ranks select the lower ID.
Output uses little-endian signed i64 values. Invalid inputs return `-1`; null
output or insufficient capacity returns `-2` without writing.

Source: “Min-Hash Sketches,” DOI
[`10.1007/978-1-4939-2864-4_573`](https://doi.org/10.1007/978-1-4939-2864-4_573).
Only the k-mins structure is profiled; bottom-k and k-partition sketches have
different state and query contracts.

| Language | Port |
|---|---|
| C | `c/m/min_hash_k_mins.c` |
| C3 | `c3/m/min_hash_k_mins.c3` |
| C++ | `cpp/m/min_hash_k_mins.cpp` |
| Elisa | `elisa/m/min_hash_k_mins.elisa` |
| Nim | `nim/m/min_hash_k_mins.nim` |
| Odin | `odin/m/min_hash_k_mins.odin` |
| Rust | `rust/m/min_hash_k_mins.rs` |
| V | `v/m/min_hash_k_mins.v` |
| Zig | `zig/m/min_hash_k_mins.zig` |
