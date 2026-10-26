# TSVC s242 fused prefix update

This package profiles the NodeSplitting s242 loop as a fused inclusive scan over three per-position input arrays plus two scalar addends. The exported symbol is tsvc_s242_fused_prefix_update and the ABI is float64_slice_io.

Input is [n,s1,s2,A[n],B[n],C[n],D[n]], with n in 1..64. All numeric values are integer-valued binary64 inputs in [-1,1]. The initial A vector is supplied explicitly. Preserve the source bounds and operation order: A[0] remains its seed; for i=1..n-1, set value=A[i-1]+s1, then add s2, then B[i], C[i], and D[i], in that left-to-right order, and store the result into A[i]. Return final A. The maximum magnitude is at most 1+5*(n-1), and all values are exactly representable in binary32 and binary64. Inputs are unchanged. Malformed input returns -1; null output or capacity below n returns -2 without writes; validation precedes output checks.

The source initializer and timing harness are excluded. The explicit A[0] field represents the initialized seed, while B/C/D and s1/s2 are supplied so the loop-body recurrence is directly benchmarkable.

## Source and rights

Pinned source: lac-dcc/Benchmarks commit 5d7b75df749241efa7a6e6f5be613d3fcc5cce38, TSVC/tsc.inc s242 (lines 2184-2205), selected by TSVC/NodeSplitting-dbl and NodeSplitting-flt. The source loops from i=1 to LEN-1 and evaluates A[i-1]+s1+s2+B[i]+C[i]+D[i] in that order. The source comments attribute codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found; these are clean-room ports and claim no upstream license. See LICENSE.txt.

Oracle: benchmarks/tsvc_s242_fused_prefix_update_oracle.py. Fixed workload: workload.json.
