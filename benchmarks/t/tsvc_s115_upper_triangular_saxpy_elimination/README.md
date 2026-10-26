# TSVC s115 upper-triangular SAXPY elimination

This clean-room bounded profile preserves s115's nested update order: for each
row index `j` in ascending order, it visits each later vector element `i` and
performs `A[i] -= U[j,i] * A[j]`. The evolving `A[j]` values feed later
updates. This is a triangular SAXPY elimination pass, not forward/backward
substitution with a diagonal division.

## Contract

Export `tsvc_s115_upper_triangular_saxpy_elimination` with
`i64_array_bytes_output`. Input is `[n,passes,A[n],U[n*n]]`, with row-major U,
`n` in 2..7, passes in 1..3, and integer values in [-1,1]. Each pass follows
ascending j then ascending i. Output is final A as little-endian signed i64;
success returns n. Malformed input returns -1. Null output or capacity below
`8*n` returns -2 without writes. The n and pass bounds limit intermediate values below 2^19, keeping all results exact in binary32/binary64 and within signed i64.

See the independent [oracle](../../tsvc_s115_upper_triangular_saxpy_elimination_oracle.py)
and [workload](workload.json).

## Source and rights

Source is `s115` in `TSVC/tsc.inc`, lines 1035–1060, pinned to LAC-DCC
[`Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1035), selected by `TSVC/LinearDependence-dbl/info.sh` (`3570 14`; float `3570 5`). The profile uses caller-supplied arrays and bounded passes instead of source initialization and timing repetitions. TSVC codelet comments attribute the collection to David Callahan, Jack Dongarra, and David Levine.

No explicit redistribution grant was found in the pinned repository material reviewed. All ports are independent clean-room implementations and reuse no upstream code/comments; no upstream license or endorsement is claimed. See [LICENSE.txt](LICENSE.txt).
