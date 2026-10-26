# TSVC s1119 same-column matrix prefix recurrence

This package models the pinned `s1119` codelet in `TSVC/tsc.inc` at commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (source lines 1179–1206; loop body
1192–1195). The LinearDependence launcher selects it
alongside s119.

The frame is `[n, passes, A[n*n], B[n*n]]`, with row-major matrices. Each pass
visits rows `i=1..n-1` and columns `j=0..n-1`, assigning
`A[i,j] = A[i-1,j] + B[i,j]`. The previous row is already updated during the
same pass, so every column is an ascending prefix recurrence. This full matrix
operation differs from s131's one-dimensional shifted update and s132's
single-row shifted-column expression; it also differs from s119's diagonal
predecessor recurrence.

The bounded domain is `2<=n<=8`, `1<=passes<=4`, and seed/matrix entries in
`{-1,0,1}`. Intermediate values remain small integers and exactly representable
in both TSVC precision families. Success returns `n*n` and the full final A
matrix as little-endian signed 64-bit values. Invalid input returns -1; null or
short output returns -2 after complete validation and before writes. The
independent oracle is `benchmarks/tsvc_s1119_same_column_matrix_prefix_oracle.py`.

Only the bounded codelet is measured, excluding TSVC initialization, timing,
repetition, and checker behavior. The pinned `s1119` function also calls
`init("s119 ")`; this profile uses explicit matrices in its frame and does not
model that source initialization typo. See `LICENSE.txt` for attribution and
rights status.
