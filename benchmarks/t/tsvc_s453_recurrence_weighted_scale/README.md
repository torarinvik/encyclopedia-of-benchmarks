# TSVC s453 recurrence-weighted vector scale

`tsvc_s453_recurrence_weighted_scale` is a bounded, clean-room profile of TSVC `s453`. The source builds a scalar induction variable by adding two before each vector element, then multiplies the current B value by that recurrence state.

## Contract

The exported symbol is `tsvc_s453_recurrence_weighted_scale` and uses the `i64_array_bytes_output` ABI.

- Input: `[n, B[n]]`.
- `n` is in `1..32`; exact input length is `1+n`.
- Every B entry is in `[-100,100]`, represented as an integer-valued source `double`. The recurrence reaches at most 64 and all products remain exactly representable in binary64 and fit signed i64.
- Run one ascending source-body pass: initialize `s=0`; for each i, add 2 to s and assign `A[i]=s*B[i]`. The equivalent result formula is `A[i]=2*(i+1)*B[i]`, but the nine ports retain the scalar recurrence. A is completely overwritten and input B is unchanged.
- Output is the complete A vector as little-endian signed i64 values. Success returns `n` and writes `8*n` bytes. Invalid input returns `-1`; null output or capacity below `8*n` returns `-2` without writes. Maximum output capacity is 256 bytes.
- The bounded profile omits TSVC's timing, initialization, dummy-call, and checksum wrappers and does not repeat the source body `2*ntimes` times. It accepts explicit integer-valued B entries instead of reproducing the source initializer's reciprocal-square values.

Fixtures include positive and signed vectors, zeros, the one-element boundary, malformed shape/range data, null input/output, and insufficient capacity. The independent oracle uses the closed-form index multiplier rather than replaying the source scalar recurrence.

## Source and rights

The codelet is `s453` at lines 4551–4575 of [`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc), selected by [`TSVC/InductionVariable-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/tsc.c) at LAC-DCC `Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh); it selects double-precision codelets and supplies `9100 14`. The TSVC `main` initializes `b` to reciprocal squares for this codelet; this profile makes B explicit.

The TSVC source attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No explicit license grant was found in the pinned TSVC files or repository material reviewed. These ports implement the bounded loop independently, reuse no upstream source code or comments, and claim no upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

## Distinction from s452

The local s452 package computes `B[i] + C[i]*(i+1)` using the array index directly and an additional vector operand. s453 computes a vector scale using a scalar recurrence that advances by two each iteration. Both are linear index-weighted maps, but the source operation and induction-variable dependency differ.

The independent oracle is [`benchmarks/tsvc_s453_recurrence_weighted_scale_oracle.py`](../../tsvc_s453_recurrence_weighted_scale_oracle.py). Suite registration is handled separately.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s453_recurrence_weighted_scale.c`](../../../c/t/tsvc_s453_recurrence_weighted_scale.c) |
| C3 | [`tsvc_s453_recurrence_weighted_scale.c3`](../../../c3/t/tsvc_s453_recurrence_weighted_scale.c3) |
| C++ | [`tsvc_s453_recurrence_weighted_scale.cpp`](../../../cpp/t/tsvc_s453_recurrence_weighted_scale.cpp) |
| Elisa | [`tsvc_s453_recurrence_weighted_scale.elisa`](../../../elisa/t/tsvc_s453_recurrence_weighted_scale.elisa) |
| Nim | [`tsvc_s453_recurrence_weighted_scale.nim`](../../../nim/t/tsvc_s453_recurrence_weighted_scale.nim) |
| Odin | [`tsvc_s453_recurrence_weighted_scale.odin`](../../../odin/t/tsvc_s453_recurrence_weighted_scale.odin) |
| Rust | [`tsvc_s453_recurrence_weighted_scale.rs`](../../../rust/t/tsvc_s453_recurrence_weighted_scale.rs) |
| V | [`tsvc_s453_recurrence_weighted_scale.v`](../../../v/t/tsvc_s453_recurrence_weighted_scale.v) |
| Zig | [`tsvc_s453_recurrence_weighted_scale.zig`](../../../zig/t/tsvc_s453_recurrence_weighted_scale.zig) |
