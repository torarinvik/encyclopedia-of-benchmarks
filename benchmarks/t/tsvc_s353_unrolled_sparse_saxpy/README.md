# TSVC s353 unrolled sparse SAXPY gather

`tsvc_s353_unrolled_sparse_saxpy` is a bounded, clean-room profile of the TSVC `s353` codelet. Each five-element chunk updates `A[i+k]` with `alpha * B[index[i+k]]`, preserving the source's five explicitly unrolled updates and gather read. Repeated gather indices are allowed; every destination position is updated once.

## Contract

The exported symbol is `tsvc_s353_unrolled_sparse_saxpy` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, alpha, A[n], B[n], indices[n]]`.
- `n` is 5, 10, 15, or 20. The exact input length is `2 + 3*n`.
- `alpha` is in `[-8,8]`; each A and B value is in `[-1,000,000,1,000,000]`; every gather index is in `[0,n-1]`.
- A and B entries stand for integer-valued source `double` values. The bounded products and sums remain exactly representable in binary64 and fit signed i64.
- Run one source-body sweep in ascending five-element chunks and source statement order: `A[i+k] += alpha * B[indices[i+k]]` for `k=0..4`. The input is unchanged.
- Output is the complete updated A vector as little-endian signed i64 values. Success returns `n` and writes `8*n` bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes.
- Bounds are intentionally much smaller than the TSVC launcher profile. The package includes no timing loop, generated TSVC arrays, dummy call, or checksum wrapper.

The hand-derived fixtures cover a five-element gather with repeated indices, a ten-element reversed gather with signed operands, a source-shaped `alpha=1` pass, malformed shape/index data, null input/output, and short capacity. The independent oracle computes each destination from the immutable input vectors and can generate expected values for every bounded valid input.

## Source and rights

The codelet is `s353` at lines 4364–4393 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/LoopRerolling-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRerolling-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRerolling-dbl/info.sh); it compiles double-precision codelets and supplies `5260 14`. The upstream wrapper repeats the loop and times it; this bounded profile isolates one sweep of the same five-way sparse SAXPY body.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the abstract bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s353_unrolled_sparse_saxpy_oracle.py`](../../tsvc_s353_unrolled_sparse_saxpy_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s353_unrolled_sparse_saxpy.c`](../../../c/t/tsvc_s353_unrolled_sparse_saxpy.c) |
| C3 | [`tsvc_s353_unrolled_sparse_saxpy.c3`](../../../c3/t/tsvc_s353_unrolled_sparse_saxpy.c3) |
| C++ | [`tsvc_s353_unrolled_sparse_saxpy.cpp`](../../../cpp/t/tsvc_s353_unrolled_sparse_saxpy.cpp) |
| Elisa | [`tsvc_s353_unrolled_sparse_saxpy.elisa`](../../../elisa/t/tsvc_s353_unrolled_sparse_saxpy.elisa) |
| Nim | [`tsvc_s353_unrolled_sparse_saxpy.nim`](../../../nim/t/tsvc_s353_unrolled_sparse_saxpy.nim) |
| Odin | [`tsvc_s353_unrolled_sparse_saxpy.odin`](../../../odin/t/tsvc_s353_unrolled_sparse_saxpy.odin) |
| Rust | [`tsvc_s353_unrolled_sparse_saxpy.rs`](../../../rust/t/tsvc_s353_unrolled_sparse_saxpy.rs) |
| V | [`tsvc_s353_unrolled_sparse_saxpy.v`](../../../v/t/tsvc_s353_unrolled_sparse_saxpy.v) |
| Zig | [`tsvc_s353_unrolled_sparse_saxpy.zig`](../../../zig/t/tsvc_s353_unrolled_sparse_saxpy.zig) |
