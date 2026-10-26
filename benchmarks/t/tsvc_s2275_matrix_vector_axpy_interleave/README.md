# TSVC s2275 interleaved matrix/vector AXPY

This package profiles the s2275 loop order: for each ascending vector index `i`, it sweeps `j` in ascending order and updates matrix cell `AA[j][i] += BB[j][i]*CC[j][i]`, then overwrites `A[i] = B[i] + C[i]*D[i]`. Each pass repeats that matrix sweep and vector overwrite. The input matrix is row-major, while the source visits it by columns (`j` outer to each fixed `i`).

## Contract

- Exported symbol: `tsvc_s2275_matrix_vector_axpy_interleave`; ABI: `float64_slice_io`.
- Input is `[n,passes,AA[n*n],BB[n*n],CC[n*n],A[n],B[n],C[n],D[n]]`, with `1 <= n <= 8`, `1 <= passes <= 8`, exact length `2+3*n*n+4*n`.
- Values are finite integer-valued binary64 values in `[-1,1]`.
- Output is `[AA_final[n*n] row-major, A_final[n]]`, count `n*n+n`. Other arrays are unchanged and input is not modified.
- Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes.
- Matrix values remain within `[-9,9]`; the overwritten vector values remain within `[-2,2]`, exactly representable in binary32 and binary64.

This is distinct from s275's guarded per-column recurrence: s2275 updates every matrix cell by an independent AXPY and then overwrites a vector element, whereas s275 conditionally propagates values down each matrix column. The package exposes both result arrays so both operations are observable.

The pinned `s275` initializer resets only AA, BB, and CC; A, B, C, and D retain suite state from earlier codelets in the original executable. This contract makes those vector inputs explicit so the bounded operation is deterministic. The vector target is the separate one-dimensional A array, not an alias into AA.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, symbol `s2275` (lines 2933–2958); it calls `init("s275 ")` (initializer case lines 510–513). The source is compiled in the `ControlFlow-dbl` and `ControlFlow-flt` launchers. TSVC comments attribute codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found in the reviewed pinned materials; these are clean-room ports. See `LICENSE.txt`.

The independent oracle is [`benchmarks/tsvc_s2275_matrix_vector_axpy_interleave_oracle.py`](../../tsvc_s2275_matrix_vector_axpy_interleave_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s2275_matrix_vector_axpy_interleave.c`](../../../c/t/tsvc_s2275_matrix_vector_axpy_interleave.c) |
| C3 | [`tsvc_s2275_matrix_vector_axpy_interleave.c3`](../../../c3/t/tsvc_s2275_matrix_vector_axpy_interleave.c3) |
| C++ | [`tsvc_s2275_matrix_vector_axpy_interleave.cpp`](../../../cpp/t/tsvc_s2275_matrix_vector_axpy_interleave.cpp) |
| Elisa | [`tsvc_s2275_matrix_vector_axpy_interleave.elisa`](../../../elisa/t/tsvc_s2275_matrix_vector_axpy_interleave.elisa) |
| Nim | [`tsvc_s2275_matrix_vector_axpy_interleave.nim`](../../../nim/t/tsvc_s2275_matrix_vector_axpy_interleave.nim) |
| Odin | [`tsvc_s2275_matrix_vector_axpy_interleave.odin`](../../../odin/t/tsvc_s2275_matrix_vector_axpy_interleave.odin) |
| Rust | [`tsvc_s2275_matrix_vector_axpy_interleave.rs`](../../../rust/t/tsvc_s2275_matrix_vector_axpy_interleave.rs) |
| V | [`tsvc_s2275_matrix_vector_axpy_interleave.v`](../../../v/t/tsvc_s2275_matrix_vector_axpy_interleave.v) |
| Zig | [`tsvc_s2275_matrix_vector_axpy_interleave.zig`](../../../zig/t/tsvc_s2275_matrix_vector_axpy_interleave.zig) |
