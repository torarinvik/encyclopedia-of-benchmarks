# TSVC s2711 nonzero-branch AXPY

This package profiles TSVC `s2711` from the `ControlFlow` family. Each pass
visits indices in ascending order and applies `A[i] += B[i] * C[i]` whenever
`B[i] != 0`. Unlike s271's strict `B[i] > 0` condition, this operation updates
for negative B values too. The local `tsvc_s271_positive_branch_axpy` package
admits negative values but intentionally leaves A unchanged for them, so the
two source predicates are observably different.

## Contract

- Symbol: `tsvc_s2711_nonzero_branch_axpy`; ABI: `i64_array_bytes_output`.
- Input: `[n, passes, A[n], B[n], C[n]]`; `1 <= n <= 64`, `1 <= passes <= 8`,
  and all array values are integers in `[-2,2]`.
- For each pass, visit indices from 0 upward. If `B[i] != 0`, update
  `A[i] = A[i] + B[i]*C[i]`. B and C are unchanged.
- Return final A as little-endian signed-i64 values and return n. Malformed
  input returns `-1`; null output or capacity below `8*n` returns `-2` without
  writes.
- The bounded integer-valued domain keeps intermediate results exactly
  representable in both TSVC double and float precision and within `[-34,34]`.
  The input arrays are explicit to expose the negative-B distinction. The
  source timing/checker loop and `4*ntimes` repetition count are excluded.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3174),
`TSVC/tsc.inc::s2711`, lines 3174–3195; launcher families are
`TSVC/ControlFlow-dbl` and `TSVC/ControlFlow-flt`. `ControlFlow-dbl/tsc.c`
selects `TYPE double` and uses run options `2325 14`; the float family selects
`TYPE float` and uses `2325 5`. TSVC source
comments attribute non-four-digit kernels to David Callahan, Jack Dongarra,
and David Levine, *Test Suite for Vectorizing Compilers*. No explicit
modification or redistribution grant was found in the pinned materials. The
ports are clean-room; see [`LICENSE.txt`](LICENSE.txt).

Primary and independent verifier models are
[`tsvc_s2711_nonzero_branch_axpy_oracle.py`](../../tsvc_s2711_nonzero_branch_axpy_oracle.py)
and [`tsvc_s2711_nonzero_branch_axpy_verifier_oracle.py`](../../tsvc_s2711_nonzero_branch_axpy_verifier_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`c/t/tsvc_s2711_nonzero_branch_axpy.c`](../../../c/t/tsvc_s2711_nonzero_branch_axpy.c) |
| C3 | [`c3/t/tsvc_s2711_nonzero_branch_axpy.c3`](../../../c3/t/tsvc_s2711_nonzero_branch_axpy.c3) |
| C++ | [`cpp/t/tsvc_s2711_nonzero_branch_axpy.cpp`](../../../cpp/t/tsvc_s2711_nonzero_branch_axpy.cpp) |
| Elisa | [`elisa/t/tsvc_s2711_nonzero_branch_axpy.elisa`](../../../elisa/t/tsvc_s2711_nonzero_branch_axpy.elisa) |
| Nim | [`nim/t/tsvc_s2711_nonzero_branch_axpy.nim`](../../../nim/t/tsvc_s2711_nonzero_branch_axpy.nim) |
| Odin | [`odin/t/tsvc_s2711_nonzero_branch_axpy.odin`](../../../odin/t/tsvc_s2711_nonzero_branch_axpy.odin) |
| Rust | [`rust/t/tsvc_s2711_nonzero_branch_axpy.rs`](../../../rust/t/tsvc_s2711_nonzero_branch_axpy.rs) |
| V | [`v/t/tsvc_s2711_nonzero_branch_axpy.v`](../../../v/t/tsvc_s2711_nonzero_branch_axpy.v) |
| Zig | [`zig/t/tsvc_s2711_nonzero_branch_axpy.zig`](../../../zig/t/tsvc_s2711_nonzero_branch_axpy.zig) |
