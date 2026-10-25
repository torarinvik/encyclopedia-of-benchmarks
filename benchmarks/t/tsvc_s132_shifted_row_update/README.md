# TSVC s132 shifted-row update

This package is a bounded clean-room implementation of TSVC `s132` from the
`GlobalDataFlow-dbl` family. The source sets `m=0`, `j=m`, and `k=m+1`; its
inner loop therefore updates row zero from the previous column of row one:
`target[i] = row1[i-1] + b[i] * c1`, for `i` from one through `n-1`. Element
zero of the target row is left unchanged. The read row is never modified, so
the inner loop's sequential order does not make later reads depend on earlier
writes.

This is a shifted cross-row update, distinct from `s131`'s one-dimensional
same-array forward-neighbor recurrence and from dense triangular solvers. It
captures the specific `s132` access pattern without carrying over the TSVC
timing harness or global initialization.

## Contract

The exported symbol is `tsvc_s132_shifted_row_update`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, row1[n], target[n], b[n], c1]`, with `n` in `2..64`.
- Every data value is in `[-1,000,000,1,000,000]`; the product and sum fit
  signed i64.
- For `i=1..n-1`, assign `target[i] = row1[i-1] + b[i]*c1`. `target[0]` is
  unchanged. The row arrays and scalar remain immutable inputs.
- On success, the final target row is emitted as little-endian signed i64
  values and the function returns `n`.
- Malformed input returns `-1`. Null output or capacity below `8*n` returns
  `-2`; validation happens first and errors write no output.

The pinned benchmark repeatedly times the same update. Because row one and
`b` are read-only and each target position is overwritten from them, additional
timing-loop repetitions do not change the final result; this package exposes
one source-shaped sweep.

## Source and rights

The behavior reference is `s132` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1449)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/GlobalDataFlow-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/GlobalDataFlow-dbl/tsc.c),
which selects `TYPE double` and the global-data-flow codelets. The source
initializes `aa` to one and initializes `b` and `c` with reciprocal-index
values; this package instead accepts bounded integer arrays to expose the
kernel's data access directly. The TSVC source attributes its non-four-digit
codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for
Vectorizing Compilers*. No explicit license grant was found in the pinned
source or repository material reviewed. The ports independently implement
the bounded mathematical loop, reuse no upstream source or comments, and claim
no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the
rights note.

The oracle and workload are
[`tsvc_s132_shifted_row_update_oracle.py`](../../tsvc_s132_shifted_row_update_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s132_shifted_row_update.c`](../../../c/t/tsvc_s132_shifted_row_update.c) |
| C3 | [`tsvc_s132_shifted_row_update.c3`](../../../c3/t/tsvc_s132_shifted_row_update.c3) |
| C++ | [`tsvc_s132_shifted_row_update.cpp`](../../../cpp/t/tsvc_s132_shifted_row_update.cpp) |
| Elisa | [`tsvc_s132_shifted_row_update.elisa`](../../../elisa/t/tsvc_s132_shifted_row_update.elisa) |
| Nim | [`tsvc_s132_shifted_row_update.nim`](../../../nim/t/tsvc_s132_shifted_row_update.nim) |
| Odin | [`tsvc_s132_shifted_row_update.odin`](../../../odin/t/tsvc_s132_shifted_row_update.odin) |
| Rust | [`tsvc_s132_shifted_row_update.rs`](../../../rust/t/tsvc_s132_shifted_row_update.rs) |
| V | [`tsvc_s132_shifted_row_update.v`](../../../v/t/tsvc_s132_shifted_row_update.v) |
| Zig | [`tsvc_s132_shifted_row_update.zig`](../../../zig/t/tsvc_s132_shifted_row_update.zig) |
