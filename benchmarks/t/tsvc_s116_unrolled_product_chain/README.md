# TSVC s116 unrolled in-place product chain

This package models the five explicitly unrolled, sequential assignments in
`s116` from `TSVC/tsc.inc` at pinned commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (source lines 1091–1117; loop body
1102–1109). The launcher is `TSVC/LinearDependence-dbl/info.sh` (the float
launcher selects the same codelet with a different timing option).

For each pass, the source visits `i=0,5,10,...` while `i<n-5` and executes in
order `A[i]=A[i+1]*A[i]`, `A[i+1]=A[i+2]*A[i+1]`, through
`A[i+4]=A[i+5]*A[i+4]`. These are in-place dependencies: later statements
consume values written by earlier statements in the same chunk. A final
sentinel at index `n-1` supplies the last product in each chunk and is not
written by that chunk.

The ABI frame is `[n, passes, A[0..n)]`. To retain the source's five-element
unroll and sentinel, `n=5*blocks+1` for 1–4 blocks (6, 11, 16, or 21), with
1–4 passes. Each input element is exactly -1 or +1, so every intermediate is
exactly representable in binary32 and binary64. Success returns `n` and emits
the full final A vector as little-endian signed 64-bit values. Invalid frames
return -1; null/short output returns -2 after validation and before mutation or
write. The oracle is independently implemented in
`benchmarks/tsvc_s116_unrolled_product_chain_oracle.py`.

The benchmark captures this bounded codelet, not TSVC's initialization,
repetition count, timing, or checker harness. See `LICENSE.txt` for attribution
and the upstream rights limitation.
