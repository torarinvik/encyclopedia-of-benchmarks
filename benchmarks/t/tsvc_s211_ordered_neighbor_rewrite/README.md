# TSVC s211 ordered neighbor rewrite

This package is a bounded clean-room implementation of TSVC `s211` from the
`StatementReordering-dbl` family. It preserves the source's two ordered
updates for each interior index:

1. `a[i] = b[i-1] + c[i]*d[i]`
2. `b[i] = b[i+1] - e[i]*d[i]`

Indices are visited upward from one through `n-2`. The first assignment reads
the preceding B element, which the previous iteration has already updated.
The second assignment reads the next B element before that later index is
changed in this pass. Preserving that order is the defining loop behavior.
The first and final elements of A and B remain unchanged.

This differs from the registered TSVC s131 and s281 recurrences: s211 updates
two arrays at each interior point and reads both neighbors of B, with one
neighbor already rewritten and the other still untouched. It also differs
from s161's mutually exclusive conditional writes.

## Contract

The exported symbol is `tsvc_s211_ordered_neighbor_rewrite`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, a[n], b[n], c[n], d[n], e[n]]`, with `n` in `3..64`
  and `passes` in `1..32`.
- Every input array element is in `[-2,2]`. The bounded recurrence remains
  exact in the source's binary64 type and well within signed i64.
- Each pass visits indices upward from one through `n-2`, applying the A
  assignment and then the B assignment at each index.
- Input is unchanged. On success, output is final A followed by final B,
  encoded as little-endian signed i64 values. The function returns `2*n`.
- Malformed input returns `-1`. Null output or capacity below `16*n` returns
  `-2`; validation happens first and errors write no output.

## Source and rights

The behavior reference is `s211` in the pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc)
(the codelet starts at [line 1832](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1832))
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`TSVC/StatementReordering-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/StatementReordering-dbl/tsc.c),
which selects `TYPE double` and the statement-reordering codelets. Source
initialization sets A to zero, B to one, and C/D/E to fractional values; this
profile accepts bounded caller arrays so both neighbor-update effects can be
observed. The TSVC source attributes its non-four-digit codelets to David
Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*. No explicit license grant was found in the pinned source or
repository material reviewed. These ports independently implement the
bounded mathematical loop, reuse no upstream source or comments, and claim no
upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the
rights note.

The oracle and cases are
[`tsvc_s211_ordered_neighbor_rewrite_oracle.py`](../../tsvc_s211_ordered_neighbor_rewrite_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s211_ordered_neighbor_rewrite.c`](../../../c/t/tsvc_s211_ordered_neighbor_rewrite.c) |
| C3 | [`tsvc_s211_ordered_neighbor_rewrite.c3`](../../../c3/t/tsvc_s211_ordered_neighbor_rewrite.c3) |
| C++ | [`tsvc_s211_ordered_neighbor_rewrite.cpp`](../../../cpp/t/tsvc_s211_ordered_neighbor_rewrite.cpp) |
| Elisa | [`tsvc_s211_ordered_neighbor_rewrite.elisa`](../../../elisa/t/tsvc_s211_ordered_neighbor_rewrite.elisa) |
| Nim | [`tsvc_s211_ordered_neighbor_rewrite.nim`](../../../nim/t/tsvc_s211_ordered_neighbor_rewrite.nim) |
| Odin | [`tsvc_s211_ordered_neighbor_rewrite.odin`](../../../odin/t/tsvc_s211_ordered_neighbor_rewrite.odin) |
| Rust | [`tsvc_s211_ordered_neighbor_rewrite.rs`](../../../rust/t/tsvc_s211_ordered_neighbor_rewrite.rs) |
| V | [`tsvc_s211_ordered_neighbor_rewrite.v`](../../../v/t/tsvc_s211_ordered_neighbor_rewrite.v) |
| Zig | [`tsvc_s211_ordered_neighbor_rewrite.zig`](../../../zig/t/tsvc_s211_ordered_neighbor_rewrite.zig) |
