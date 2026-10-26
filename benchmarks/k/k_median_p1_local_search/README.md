# K-median p=1 local search

This package implements a bounded deterministic specialization of the p-swap
local-search method described in Chapter 212 of the *Encyclopedia of
Algorithms*. It uses the k-median objective over a supplied finite metric and
the chapter's p-swap neighborhood with p=1: replace one current center by one
candidate not currently selected. Starting from the supplied feasible center
set, each iteration chooses the neighbor with minimum objective among all
strictly improving one-swaps. Objective ties are resolved by the
lexicographically smallest sorted center list. The process stops when no
strictly improving one-swap exists.

## Contract

ABI: `i64_array_bytes_output`; symbol: `k_median_p1_local_search`.
Input is `[n,k, D row-major (n*n values), k initial center IDs]`.
`2<=n<=12`, `1<=k<=min(4,n)`, distances are symmetric integer metric values
in `[0,1000]`, with zero diagonal, positive off-diagonal entries, and triangle
inequality. Initial IDs are distinct and in `[0,n)`. Maximum input is 150
signed 64-bit words. Output is `[minimum total demand-to-nearest-center
distance, k, sorted final center IDs]`, each as little-endian signed 64-bit;
maximum output is 48 bytes. Malformed input returns `-1` before output checks;
null or short output returns `-2` without writes.

This is a bounded deterministic p=1 best-improvement profile. It does not
claim the chapter's arbitrary-p locality-gap guarantee, nor does it implement
facility-location opening costs, capacitated variants, or randomized
initialization. It is distinct from the Rodinia `streamcluster_pgain` helper,
which evaluates a facility-opening move with reassignment/closure costs.

## Source and rights

Source chapter: Kamesh Munagala, “Local Search for K-medians and Facility
Location,” DOI
[`10.1007/978-1-4939-2864-4_212`](https://doi.org/10.1007/978-1-4939-2864-4_212).
The code is independently written and contains no copied book text or code;
see [`RIGHTS.md`](RIGHTS.md).

Primary oracle: [`k_median_p1_local_search_oracle.py`](../../k_median_p1_local_search_oracle.py).
Independent verifier: [`k_median_p1_local_search_verifier_oracle.py`](../../k_median_p1_local_search_verifier_oracle.py).
Fixtures: [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | `c/k/k_median_p1_local_search.c` |
| C3 | `c3/k/k_median_p1_local_search.c3` |
| C++ | `cpp/k/k_median_p1_local_search.cpp` |
| Elisa | `elisa/k/k_median_p1_local_search.elisa` |
| Nim | `nim/k/k_median_p1_local_search.nim` |
| Odin | `odin/k/k_median_p1_local_search.odin` |
| Rust | `rust/k/k_median_p1_local_search.rs` |
| V | `v/k/k_median_p1_local_search.v` |
| Zig | `zig/k/k_median_p1_local_search.zig` |
