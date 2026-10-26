# TSVC s3251 forward-shifted array expansion

This package profiles the Expansion-family s3251 dependence chain. For ascending indices `i=0..n-2`, it stores `A[i+1]=B[i]+C[i]`, then `B[i]=C[i]*E[i]`, then `D[i]=A[i]*E[i]`. The last assignment reads the current `A[i]`: at `i>0`, that value was written by the previous iteration. The output exposes final A, B, and D so the forward dependency and untouched tail cells remain visible.

## Contract

The exported symbol is `tsvc_s3251_forward_shifted_array_expansion`, using `float64_slice_io`.

- Input is `[n,A[n],B[n],C[n],D[n],E[n]]`; `n` is 1 through 64 and the length is exactly `1+5*n`.
- Array values are finite integer-valued binary64 values in `[-1,1]`; all intermediate values are exact in both binary32 and binary64.
- Visit indices in ascending order through `n-2`, preserving the three source statements and their order. For `n=1` the loop performs no writes.
- Return `[A_final[n],B_final[n],D_final[n]]`, count `3*n`; input remains unchanged.
- Invalid input returns `-1`. Null output or insufficient capacity returns `-2` without writes.

The pinned function calls `init("s251 ")`, whose source initializer sets A to zero, B to one, and C/D/E to reciprocal values `1/(i+1)`. This package makes all five arrays explicit caller inputs and uses a bounded integer-valued domain so the double and float-family arithmetic agrees exactly; it does not claim to reproduce the initializer's full fractional profile. Timing, repeated calls, and the checksum checker are outside the contract.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, function `s3251` lines 2396–2419, selected through `TSVC/Expansion-dbl/info.sh` and `TSVC/Expansion-flt/info.sh`. The comments attribute the TSVC codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found in the reviewed pinned materials. The nine ports are clean-room implementations and do not copy upstream code or comments; see `LICENSE.txt`.

This operation is separate from the existing s221/s2251/s1251 profiles: it carries state through a forward `A[i+1]` write, then updates B and D from the current arrays. It has neither s2251's single carried scalar nor s1251's independent per-index B/C/D update.

The independent oracle is [`benchmarks/tsvc_s3251_forward_shifted_array_expansion_oracle.py`](../../tsvc_s3251_forward_shifted_array_expansion_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s3251_forward_shifted_array_expansion.c`](../../../c/t/tsvc_s3251_forward_shifted_array_expansion.c) |
| C3 | [`tsvc_s3251_forward_shifted_array_expansion.c3`](../../../c3/t/tsvc_s3251_forward_shifted_array_expansion.c3) |
| C++ | [`tsvc_s3251_forward_shifted_array_expansion.cpp`](../../../cpp/t/tsvc_s3251_forward_shifted_array_expansion.cpp) |
| Elisa | [`tsvc_s3251_forward_shifted_array_expansion.elisa`](../../../elisa/t/tsvc_s3251_forward_shifted_array_expansion.elisa) |
| Nim | [`tsvc_s3251_forward_shifted_array_expansion.nim`](../../../nim/t/tsvc_s3251_forward_shifted_array_expansion.nim) |
| Odin | [`tsvc_s3251_forward_shifted_array_expansion.odin`](../../../odin/t/tsvc_s3251_forward_shifted_array_expansion.odin) |
| Rust | [`tsvc_s3251_forward_shifted_array_expansion.rs`](../../../rust/t/tsvc_s3251_forward_shifted_array_expansion.rs) |
| V | [`tsvc_s3251_forward_shifted_array_expansion.v`](../../../v/t/tsvc_s3251_forward_shifted_array_expansion.v) |
| Zig | [`tsvc_s3251_forward_shifted_array_expansion.zig`](../../../zig/t/tsvc_s3251_forward_shifted_array_expansion.zig) |
