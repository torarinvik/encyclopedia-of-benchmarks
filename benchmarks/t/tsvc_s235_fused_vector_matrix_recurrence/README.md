# TSVC s235 fused vector and matrix recurrence

This package models s235 from `TSVC/tsc.inc` at pinned commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (source lines 2218–2244; loop body
2230–2236), selected by `TSVC/LoopRestructuring-dbl/info.sh`.

The input frame is `[n,A[n],B[n],C[n],AA[n*n],BB[n*n]]`, with row-major
matrices. The outer loop advances columns `i=0..n-1`; first it updates
`A[i] += B[i]*C[i]`, then updates rows `j=1..n-1` in that column by
`AA[j,i] = AA[j-1,i] + BB[j,i]*A[i]`. The matrix recurrence therefore uses
the freshly updated vector value. Success returns `n+n*n` and emits `[A,AA]`
as little-endian signed 64-bit values.

The bounded profile uses `2<=n<=8`, one pass, and all input entries in
`{-1,0,1}`. The vector values are at most 2 in magnitude and matrix recurrence
intermediates remain small exact integers in both TSVC precision families.
Invalid inputs return -1; null or insufficient output returns -2 after
validation and before writes. The independent oracle is
`benchmarks/tsvc_s235_fused_vector_matrix_recurrence_oracle.py`.

This package covers the fused kernel only, excluding TSVC initialization,
timing/repetition, and checker behavior. See `LICENSE.txt` for attribution and
rights status.
