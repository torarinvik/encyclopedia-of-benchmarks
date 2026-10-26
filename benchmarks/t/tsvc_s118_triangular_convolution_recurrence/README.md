# TSVC s118 triangular convolution recurrence

This profile models the nested recurrence in `s118` from `TSVC/tsc.inc` at
pinned commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38` (kernel lines
1121–1146; recurrence loops 1133–1138). The launcher is
`TSVC/LinearDependence-dbl/info.sh` (the float family selects the same codelet
with a different timing option).

The input frame is `[n, passes, A[n], BB[n*n]]`; `BB` is row-major. For each
pass, the source visits `i=1..n-1`, then `j=0..i-1`, applying
`A[i] += BB[j,i] * A[i-j-1]`. The loop order matters because earlier `A`
coefficients are consumed and the current `A[i]` accumulates terms in order.
This recursive triangular coefficient generation is distinct from ordinary
linear convolution, which multiplies two fixed input sequences.

The bounded contract uses `2<=n<=8`, `1<=passes<=4`, and initial A/matrix
entries in `{-1,0,1}`; this keeps every intermediate comfortably within the
exact integer range of both source precision families. Success returns `n` and
the final A vector as little-endian signed 64-bit values. Invalid input returns
-1; a null or short output returns -2 after full input validation and before
any write. The independent oracle is
`benchmarks/tsvc_s118_triangular_convolution_recurrence_oracle.py`.

The package covers the bounded codelet only, not TSVC initialization, its
timing/repetition profile, or the checker. See `LICENSE.txt` for source
attribution and rights status.
