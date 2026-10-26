# TSVC s1213 ordered neighbor array map

This package models the selected `s1213` operation in `TSVC/tsc.inc` at pinned
commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (source lines 1961–1984; loop
body 1972–1976), selected by `TSVC/StatementReordering-dbl/info.sh`.

The frame is `[n,A[n],B[n],C[n],D[n]]`. For each ascending `i=1..n-2`, the
source first assigns `A[i]=B[i-1]+C[i]`, then assigns `B[i]=A[i+1]*D[i]`.
Because the loop advances in place, the next iteration reads the B value just
written at its preceding index, while the A lookahead remains unmodified until
that next iteration. This ordered pair of overwrite maps differs from s211's
neighbor formulas and s212's multiply/accumulate update.

The bounded contract uses `3<=n<=32` and input values in `{-1,0,1}`. It runs
one pass, returns both final arrays as `[A...,B...]` little-endian signed
64-bit values, and reports `2*n` output elements. Invalid frames return -1;
null or insufficient output returns -2 after validation and before writes.
The independent oracle is
`benchmarks/tsvc_s1213_ordered_neighbor_array_map_oracle.py`.

Only the bounded codelet is measured; TSVC initialization, repeated timing, and
checker behavior are excluded. See `LICENSE.txt` for attribution and rights
status.
