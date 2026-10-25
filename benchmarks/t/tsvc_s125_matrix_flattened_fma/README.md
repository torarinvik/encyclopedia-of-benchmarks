# TSVC s125 flattened matrix multiply-add

`tsvc_s125_matrix_flattened_fma` is a bounded, clean-room profile of TSVC `s125`. It traverses three row-major matrices with nested row and column loops, incrementing a flat output index and computing:

`output[row*n+column] = AA[row,column] + BB[row,column]*CC[row,column]`

The operation is an elementwise matrix multiply-add followed by row-major flattening, not a matrix product.

## Contract

The exported symbol is `tsvc_s125_matrix_flattened_fma` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, AA[n*n], BB[n*n], CC[n*n]]`, with matrices in row-major order.
- `n` is in `1..8`; exact input length is `1 + 3*n*n`.
- Every matrix value is in `[-100,100]`, representing integer-valued source `double` elements. The bounded products and sums remain exactly representable in binary64 and fit signed i64.
- Run one nested row-major sweep. The source's flat index starts at -1 and increments before each output assignment; the output index therefore matches the row-major matrix offset.
- Output is all `n*n` elementwise multiply-add values as little-endian signed i64. Success returns `n*n` and writes `8*n*n` bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Input is unchanged.
- The profile excludes the TSVC timing, initialization, dummy-call, and checksum wrappers and does not repeat the source body `100*(ntimes/LEN2)` times.

Fixtures cover a 2x2 signed matrix, a hand-derived 3x3 row-major result, the 1x1 boundary, malformed dimensions/ranges, null pointers, and insufficient capacity. The independent oracle uses a flat offset map for the three immutable input matrices.

## Source and rights

The codelet is `s125` at lines 1344–1372 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s125_matrix_flattened_fma_oracle.py`](../../tsvc_s125_matrix_flattened_fma_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s125_matrix_flattened_fma.c`](../../../c/t/tsvc_s125_matrix_flattened_fma.c) |
| C3 | [`tsvc_s125_matrix_flattened_fma.c3`](../../../c3/t/tsvc_s125_matrix_flattened_fma.c3) |
| C++ | [`tsvc_s125_matrix_flattened_fma.cpp`](../../../cpp/t/tsvc_s125_matrix_flattened_fma.cpp) |
| Elisa | [`tsvc_s125_matrix_flattened_fma.elisa`](../../../elisa/t/tsvc_s125_matrix_flattened_fma.elisa) |
| Nim | [`tsvc_s125_matrix_flattened_fma.nim`](../../../nim/t/tsvc_s125_matrix_flattened_fma.nim) |
| Odin | [`tsvc_s125_matrix_flattened_fma.odin`](../../../odin/t/tsvc_s125_matrix_flattened_fma.odin) |
| Rust | [`tsvc_s125_matrix_flattened_fma.rs`](../../../rust/t/tsvc_s125_matrix_flattened_fma.rs) |
| V | [`tsvc_s125_matrix_flattened_fma.v`](../../../v/t/tsvc_s125_matrix_flattened_fma.v) |
| Zig | [`tsvc_s125_matrix_flattened_fma.zig`](../../../zig/t/tsvc_s125_matrix_flattened_fma.zig) |
