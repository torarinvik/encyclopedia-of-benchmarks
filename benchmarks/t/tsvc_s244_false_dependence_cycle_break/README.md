# TSVC s244 false-dependence cycle break

`tsvc_s244_false_dependence_cycle_break` is a bounded, clean-room profile of TSVC `s244`. The loop alternates a pointwise A update, a B update, and a write to the next A position. That final write is overwritten at the next iteration for every non-tail position, which is the false-dependence pattern the codelet exposes.

## Contract

The exported symbol is `tsvc_s244_false_dependence_cycle_break` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, A[n], B[n], C[n], D[n]]`.
- `n` is in `2..32`; exact input length is `1 + 4*n`. Every A, B, C, and D value is in `[-2,2]`, represented as an integer-valued source `double`. Products and sums are exact in binary64 and remain small signed integers.
- Run one ascending source-body sweep for `i=0..n-2`, in this exact order: `A[i]=B[i]+C[i]*D[i]`; `B[i]=C[i]+B[i]`; then `A[i+1]=B[i]+A[i+1]*D[i]`, using the updated B and pre-store next A. The last statement's intermediate value is overwritten by the next iteration except at the tail.
- Output is final A[n], final B[n], then a trace of each third-statement result `A[i+1]` immediately after that store, all as little-endian signed i64. The trace deliberately keeps the source's transient third statement observable; its final trace entry duplicates final A[n-1]. Success returns `3*n-1` values and writes `8*(3*n-1)` bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes. Input is unchanged.
- The bounded profile omits timing, initialization, dummy-call, and checksum wrappers and runs one source-body pass rather than repeating the loop `ntimes` times. It accepts explicit arrays; the source initializer uses A=0, B=1, and C=D=1e-6.

Fixtures cover the transient write and its overwrite, the minimum vector, malformed shape/range data, null pointers, and insufficient capacity. The oracle derives final A/B and the pre-overwrite trace by direct formulas rather than replaying source statements.

## Source and rights

The codelet is `s244` at lines 2237–2261 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/NodeSplitting-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/NodeSplitting-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The pinned [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/NodeSplitting-dbl/info.sh) compiles `dummy.c` and `tsc.c` with `-std=gnu99 -lm` and supplies `10000 14`. The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle is [`benchmarks/tsvc_s244_false_dependence_cycle_break_oracle.py`](../../tsvc_s244_false_dependence_cycle_break_oracle.py). Suite registration is handled separately.

This is distinct from the local [`s241` cross-coupled product map](../tsvc_s241_cross_coupled_product_map/README.md): s241 multiplies adjacent A values into B, while s244 performs an affine A write, an additive B update, and a next-position A transform with a transient-store trace.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s244_false_dependence_cycle_break.c`](../../../c/t/tsvc_s244_false_dependence_cycle_break.c) |
| C3 | [`tsvc_s244_false_dependence_cycle_break.c3`](../../../c3/t/tsvc_s244_false_dependence_cycle_break.c3) |
| C++ | [`tsvc_s244_false_dependence_cycle_break.cpp`](../../../cpp/t/tsvc_s244_false_dependence_cycle_break.cpp) |
| Elisa | [`tsvc_s244_false_dependence_cycle_break.elisa`](../../../elisa/t/tsvc_s244_false_dependence_cycle_break.elisa) |
| Nim | [`tsvc_s244_false_dependence_cycle_break.nim`](../../../nim/t/tsvc_s244_false_dependence_cycle_break.nim) |
| Odin | [`tsvc_s244_false_dependence_cycle_break.odin`](../../../odin/t/tsvc_s244_false_dependence_cycle_break.odin) |
| Rust | [`tsvc_s244_false_dependence_cycle_break.rs`](../../../rust/t/tsvc_s244_false_dependence_cycle_break.rs) |
| V | [`tsvc_s244_false_dependence_cycle_break.v`](../../../v/t/tsvc_s244_false_dependence_cycle_break.v) |
| Zig | [`tsvc_s244_false_dependence_cycle_break.zig`](../../../zig/t/tsvc_s244_false_dependence_cycle_break.zig) |
