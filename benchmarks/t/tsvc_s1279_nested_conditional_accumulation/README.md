# TSVC s1279 nested conditional accumulation

This package profiles the pinned ControlFlow codelet s1279. In each pass, it visits indices in ascending order and performs `C[i] += D[i]*E[i]` only when both `A[i] < 0` and `B[i] > A[i]` hold. The predicates are strict and are evaluated from the supplied A and B arrays; those arrays are read-only.

## Contract

- The exported symbol is `tsvc_s1279_nested_conditional_accumulation`, using `float64_slice_io`.
- Input is `[n,passes,A[n],B[n],C[n],D[n],E[n]]`, with `1 <= n <= 64`, `1 <= passes <= 8`, and exact length `2+5*n`.
- Scalar and array values are finite integer-valued binary64 values in `[-1,1]`.
- Output is final C in index order, with count `n`. A, B, D, and E are unchanged; input is not modified.
- Invalid input returns `-1`. Null output or insufficient capacity returns `-2` without writes.
- The bounded integer domain keeps the source-ordered updates exact in binary32 and binary64. C remains in `[-9,9]`.

Fixtures exercise the taken path, the outer predicate failing, and the outer predicate passing while the inner predicate fails, along with equality boundaries, repeated passes, malformed frames, and output errors.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, symbol `s1279` (lines 3102–3129); the codelet invokes `init("s279 ")` (initializer case in `TSVC/tsc.inc`, lines 533–540). The codelet is selected by `TSVC/ControlFlow-dbl/info.sh` and `TSVC/ControlFlow-flt/info.sh`. TSVC source comments attribute codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found in the reviewed pinned materials; these are clean-room ports. See `LICENSE.txt`.

The independent oracle is [`benchmarks/tsvc_s1279_nested_conditional_accumulation_oracle.py`](../../tsvc_s1279_nested_conditional_accumulation_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s1279_nested_conditional_accumulation.c`](../../../c/t/tsvc_s1279_nested_conditional_accumulation.c) |
| C3 | [`tsvc_s1279_nested_conditional_accumulation.c3`](../../../c3/t/tsvc_s1279_nested_conditional_accumulation.c3) |
| C++ | [`tsvc_s1279_nested_conditional_accumulation.cpp`](../../../cpp/t/tsvc_s1279_nested_conditional_accumulation.cpp) |
| Elisa | [`tsvc_s1279_nested_conditional_accumulation.elisa`](../../../elisa/t/tsvc_s1279_nested_conditional_accumulation.elisa) |
| Nim | [`tsvc_s1279_nested_conditional_accumulation.nim`](../../../nim/t/tsvc_s1279_nested_conditional_accumulation.nim) |
| Odin | [`tsvc_s1279_nested_conditional_accumulation.odin`](../../../odin/t/tsvc_s1279_nested_conditional_accumulation.odin) |
| Rust | [`tsvc_s1279_nested_conditional_accumulation.rs`](../../../rust/t/tsvc_s1279_nested_conditional_accumulation.rs) |
| V | [`tsvc_s1279_nested_conditional_accumulation.v`](../../../v/t/tsvc_s1279_nested_conditional_accumulation.v) |
| Zig | [`tsvc_s1279_nested_conditional_accumulation.zig`](../../../zig/t/tsvc_s1279_nested_conditional_accumulation.zig) |
