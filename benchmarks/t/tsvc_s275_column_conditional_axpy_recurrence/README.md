# TSVC s275 conditional column AXPY recurrence

This package isolates the `s275` codelet in the pinned TSVC `ControlFlow-dbl` and `ControlFlow-flt` launchers. For each column `i`, it tests the original top-row value `A[0,i]`; if positive, it walks rows upward from 1 and applies `A[j,i] = A[j-1,i] + B[j,i] * C[j,i]`. The row dependency is in-place and ordered, and the guard suppresses the entire column update. The source loop order is column outer, row inner.

The bounded input is `[n, A row-major n×n, B row-major n×n, C row-major n×n]`, `1 <= n <= 8`, with finite integer-valued entries in `[-16,16]`. Output is the complete final A matrix in row-major order. The limits keep all intermediate integers exactly representable in both source precisions. Invalid input returns `-1`; null output or insufficient capacity returns `-2` after input validation. ABI: `float64_slice_io`.

Pinned provenance: `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc::s275` (lines 2904–2931), selected by `TSVC/ControlFlow-dbl/info.sh` and `TSVC/ControlFlow-flt/info.sh`. Their launcher profiles use `2325 14` and `2325 5`, respectively; this package executes one bounded pass. TSVC attributes the non-four-digit loops to David Callahan, Jack Dongarra, and David Levine. No explicit redistribution grant was found; all ports are clean-room and reuse no upstream code or comments.

See [workload.json](workload.json), [LICENSE.txt](LICENSE.txt), and the [independent oracle](../../tsvc_s275_column_conditional_axpy_recurrence_oracle.py). Nine language ports are included.
