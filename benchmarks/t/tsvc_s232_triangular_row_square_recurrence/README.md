# TSVC s232 triangular row square recurrence

This profile implements the selected `s232` operation from `TSVC/tsc.inc` at
pinned commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (source lines
2101–2126; nested recurrence at 2113–2118). The launcher is
`TSVC/LoopRestructuring-dbl/info.sh`.

The input frame is `[n, A[n*n], B[n*n]]` with row-major matrices. In source
order, rows `j=1..n-1` and columns `i=1..j` are updated as
`A[j,i] = A[j,i-1]^2 + B[j,i]`. Each step reads the value written at the
previous column of that row, so the lower-triangular recurrence is observable.
The bounded contract uses `2<=n<=5` and initial A/B values in `{-1,0,1}`; the
largest possible recurrence value remains below 2^10, exact for both source
precision families. Success returns `n*n` and the entire final A matrix as
little-endian signed 64-bit values; invalid frames return -1 and null/short
output returns -2 before mutation or writes.

The oracle is `benchmarks/tsvc_s232_triangular_row_square_recurrence_oracle.py`.
The profile excludes TSVC initialization, repetition/timing, and checker code.
See `LICENSE.txt` for attribution and rights status.
