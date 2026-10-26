# TSVC s233/s2233 paired matrix prefix recurrences

The pinned LoopRestructuring launcher selects both `s233` and `s2233` from
`TSVC/tsc.inc` at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (s233
lines 2157–2185, s2233 lines 2187–2215). They share a same-column recurrence
for A, then differ in the direction of the second B recurrence.

The frame `[n, mode, A[n*n], B[n*n], C[n*n]]` uses row-major matrices. Both
modes first update A for columns `i=1..n-1`, rows `j=1..n-1`:
`A[j,i]=A[j-1,i]+C[j,i]`. Mode 0 is s233 and updates B horizontally as
`B[j,i]=B[j,i-1]+C[j,i]` in ascending columns. Mode 1 is s2233 and updates B
vertically as `B[i,j]=B[i-1,j]+C[i,j]` in ascending rows. Both final matrices
are emitted as `[A row-major, B row-major]` little-endian signed 64-bit values.

The bounded domain is `2<=n<=8`, mode 0 or 1, and all matrix inputs in
`{-1,0,1}`. One pass is modeled; all results remain small exact integers in
both TSVC precision families. Invalid frames return -1; null or short output
returns -2 after validation and before writes. The independent oracle is
`benchmarks/tsvc_s233_s2233_matrix_prefix_oracle.py`.

The profiles expose the selected matrix operations only; TSVC initialization,
timing repetitions, and checker behavior are excluded. See `LICENSE.txt` for
attribution and rights status.
