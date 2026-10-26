# TSVC s113 invariant-anchor addition

This clean-room bounded profile preserves the ascending loop `A[i] = A[0] +
B[i]` for `i=1..n-1`. Since index zero is never written, every iteration reads
the same invariant anchor. This is distinct from s1113, where the anchor index
is itself overwritten and later iterations observe that update, and from s293,
which broadcasts A[0] without adding B.

## Contract

Export `tsvc_s113_invariant_anchor_add` with `i64_array_bytes_output`. Input is
`[n,A[n],B[n]]`, n=1..64, with all values in [-2,2]. Output is final A in
little-endian signed i64 and success returns n. Malformed input returns -1;
null output or capacity below `8*n` returns -2 without writes. The bounded
integer results are exact in both TSVC precision families.

See the independent [oracle](../../tsvc_s113_invariant_anchor_add_oracle.py)
and [workload](workload.json).

## Source and rights

Source is `s113` in `TSVC/tsc.inc`, lines 952–975, pinned to LAC-DCC
[`Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L952). It is selected by `TSVC/LinearDependence-dbl/info.sh` (`3570 14`; float `3570 5`). TSVC codelet comments attribute this collection to David Callahan, Jack Dongarra, and David Levine.

No explicit redistribution grant was found in the pinned source/repository material reviewed. The ports are independent clean-room implementations and reuse no upstream code or comments; no upstream license or endorsement is claimed. See [LICENSE.txt](LICENSE.txt).
