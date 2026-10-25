# TSVC s114 transposed lower-triangle update

`tsvc_s114_transposed_lower_triangle_update` is a bounded, clean-room profile of the TSVC `s114` matrix codelet. It updates only the strict lower triangle of A, reading the transposed upper-triangle element and adding B:

`A[i,j] = A[j,i] + B[i,j]`, for rows `i=0..n-1` and columns `j=0..i-1`.

The row-major input matrices are explicit and integer-valued. This keeps the original source's `double` addition exact while making every lower-triangle result directly observable. It differs from a full matrix transpose: diagonal and upper-triangle A entries are unchanged, and each lower entry receives an addition from B.

## Contract

The exported symbol is `tsvc_s114_transposed_lower_triangle_update` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, A[n*n], B[n*n]]`, with each matrix in row-major order.
- `n` is in `2..16`; input length is exactly `1 + 2*n*n`.
- Every A and B element is a signed integer in `[-1,000,000,1,000,000]`, represented exactly as a source `double`.
- Run the s114 nested loops once in source order: `i` ascends, then `j` ascends over `0..i-1`; update the local A copy in place from `A[j*n+i] + B[i*n+j]`.
- Output is the complete final A matrix, row-major, little-endian signed i64. The function returns `n*n` values (`8*n*n` bytes).
- Malformed input returns `-1`; null output or capacity below `8*n*n` returns `-2` without writes. Input memory is unchanged.

The workload has small hand-derived matrices, signed values, and malformed/capacity cases. The independent oracle uses a separately written row-major pair of loops; its result is also available for generated bounded verifier cases.

## Source and rights

The codelet is `s114` in [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1004-L1031), selected by the pinned [`TSVC/LinearDependence-dbl` source directory](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LinearDependence-dbl) and [`tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LinearDependence-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher, [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LinearDependence-dbl/info.sh), compiles the double-precision TSVC codelets and runs `3570 14`; this profile isolates one bounded kernel invocation and excludes timing and dummy-call wrappers.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned source or repository material reviewed. These ports are independent implementations of the bounded loop contract; they reuse no upstream code or comments and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle is [`benchmarks/tsvc_s114_transposed_lower_triangle_update_oracle.py`](../../tsvc_s114_transposed_lower_triangle_update_oracle.py). The suite wiring is intentionally separate from this package artifact.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s114_transposed_lower_triangle_update.c`](../../../c/t/tsvc_s114_transposed_lower_triangle_update.c) |
| C3 | [`tsvc_s114_transposed_lower_triangle_update.c3`](../../../c3/t/tsvc_s114_transposed_lower_triangle_update.c3) |
| C++ | [`tsvc_s114_transposed_lower_triangle_update.cpp`](../../../cpp/t/tsvc_s114_transposed_lower_triangle_update.cpp) |
| Elisa | [`tsvc_s114_transposed_lower_triangle_update.elisa`](../../../elisa/t/tsvc_s114_transposed_lower_triangle_update.elisa) |
| Nim | [`tsvc_s114_transposed_lower_triangle_update.nim`](../../../nim/t/tsvc_s114_transposed_lower_triangle_update.nim) |
| Odin | [`tsvc_s114_transposed_lower_triangle_update.odin`](../../../odin/t/tsvc_s114_transposed_lower_triangle_update.odin) |
| Rust | [`tsvc_s114_transposed_lower_triangle_update.rs`](../../../rust/t/tsvc_s114_transposed_lower_triangle_update.rs) |
| V | [`tsvc_s114_transposed_lower_triangle_update.v`](../../../v/t/tsvc_s114_transposed_lower_triangle_update.v) |
| Zig | [`tsvc_s114_transposed_lower_triangle_update.zig`](../../../zig/t/tsvc_s114_transposed_lower_triangle_update.zig) |
