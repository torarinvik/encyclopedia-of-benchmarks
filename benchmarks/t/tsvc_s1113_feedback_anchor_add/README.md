# TSVC s1113 feedback-anchor addition

This clean-room profile preserves the ascending source loop
`A[i] = A[n//2] + B[i]` for every i. The anchor element is part of the write
set. At index `n//2`, its old value is used to update itself; all later
iterations read that new value. This source-order feedback distinguishes s1113
from s113, whose anchor A[0] is never overwritten.

## Contract

Export `tsvc_s1113_feedback_anchor_add` with `i64_array_bytes_output`. Input is
`[n,A[n],B[n]]`, n=1..64, with values in [-2,2]. Output is the final A vector
as little-endian signed i64; success returns n. Invalid input returns -1;
null output or capacity below `8*n` returns -2 without writes. Values remain
small and exactly representable in the TSVC float and double families.

See the independent [oracle](../../tsvc_s1113_feedback_anchor_add_oracle.py)
and [workload](workload.json).

## Source and rights

Source is `s1113` in `TSVC/tsc.inc`, lines 977–1000, pinned to LAC-DCC
[`Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L977), selected by `TSVC/LinearDependence-dbl/info.sh` (`3570 14`; float `3570 5`). The source loop includes i=0 and writes the midpoint anchor in place. TSVC codelets are attributed in comments to David Callahan, Jack Dongarra, and David Levine.

No explicit redistribution grant was found in the pinned repository material reviewed. The ports are independent clean-room implementations; no upstream source/comments, license, or endorsement is claimed. See [LICENSE.txt](LICENSE.txt).
