# TSVC s258 wrapped scalar expansion

`tsvc_s258_wrapped_scalar_expansion` is a bounded, clean-room profile of TSVC Expansion codelet `s258`. A scalar starts at zero at the beginning of each pass. During the ascending element sweep, a positive A value refreshes the scalar to `D[i] * D[i]`; otherwise the scalar carries forward unchanged. The current scalar then drives two separate writes, to B and E.

## Contract

The exported symbol is `tsvc_s258_wrapped_scalar_expansion` and uses the `i64_array_scalar` ABI.

- Input: `[n, A[n], C[n], D[n], AA0[n]]`, where `AA0` represents row zero of the source matrix `aa`.
- `n` is in `1..64`; exact input length is `1 + 4*n`.
- Every input value is in `[0,2]`, interpreted as an integer-valued source `double` or `float`. The carried scalar is at most 4, B and E elements are at most 10, and the final checksum is at most 1280. All operations remain exact in both source precisions.
- Initialize `s=0`. For ascending `i=0..n-1`, if `A[i] > 0`, assign `s=D[i]*D[i]`; then assign `B[i]=s*C[i]+D[i]` followed by `E[i]=(s+1)*AA0[i]`.
- Return `sum(B) + sum(E)`, matching the source's final `check(25)` projection. The nonnegative input domain keeps valid checksums distinct from the `-1` invalid-input result.
- Invalid or null input returns `-1`. Inputs are unchanged.

This profile runs one pass and omits the timing and dummy-call wrapper. The explicit vectors replace TSVC's shared global-array setup and make the scalar refresh/carry behavior deterministic. The oracle independently evaluates the carried scalar and both output sums.

## Source and rights

The codelet is `s258` at lines 2598–2624 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by the double-precision [`Expansion-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/tsc.c) and float [`Expansion-flt/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-flt/tsc.c), at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launchers use `4160 14` (double) and `4160 5` (float). The TSVC source comments attribute its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports are clean-room implementations of the bounded operation, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s258_wrapped_scalar_expansion_oracle.py`](../../tsvc_s258_wrapped_scalar_expansion_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s258_wrapped_scalar_expansion.c`](../../../c/t/tsvc_s258_wrapped_scalar_expansion.c) |
| C3 | [`tsvc_s258_wrapped_scalar_expansion.c3`](../../../c3/t/tsvc_s258_wrapped_scalar_expansion.c3) |
| C++ | [`tsvc_s258_wrapped_scalar_expansion.cpp`](../../../cpp/t/tsvc_s258_wrapped_scalar_expansion.cpp) |
| Elisa | [`tsvc_s258_wrapped_scalar_expansion.elisa`](../../../elisa/t/tsvc_s258_wrapped_scalar_expansion.elisa) |
| Nim | [`tsvc_s258_wrapped_scalar_expansion.nim`](../../../nim/t/tsvc_s258_wrapped_scalar_expansion.nim) |
| Odin | [`tsvc_s258_wrapped_scalar_expansion.odin`](../../../odin/t/tsvc_s258_wrapped_scalar_expansion.odin) |
| Rust | [`tsvc_s258_wrapped_scalar_expansion.rs`](../../../rust/t/tsvc_s258_wrapped_scalar_expansion.rs) |
| V | [`tsvc_s258_wrapped_scalar_expansion.v`](../../../v/t/tsvc_s258_wrapped_scalar_expansion.v) |
| Zig | [`tsvc_s258_wrapped_scalar_expansion.zig`](../../../zig/t/tsvc_s258_wrapped_scalar_expansion.zig) |
