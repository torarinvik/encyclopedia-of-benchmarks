# TSVC s2712 comparison-gated AXPY

This package profiles ControlFlow s2712. For each pass and each index in ascending order, it updates `A[i] += B[i]*C[i]` only when the current `A[i] > B[i]`. A is the only mutated array, so the predicate is reevaluated against the accumulated A on every pass.

## Contract

The exported symbol is `tsvc_s2712_comparison_gated_axpy`, using `float64_slice_io`.

- Input is `[n,passes,A[n],B[n],C[n]]`; `n` is 1 through 64, passes is 1 through 8, and length is exactly `2+3*n`.
- Array values are finite integer-valued binary64 values in `[-2,2]`.
- For each pass, visit i ascending and apply the strict comparison `A[i] > B[i]` before the update. B and C remain unchanged.
- Return final A as n binary64 values; input is unchanged.
- Invalid input returns `-1`. Null output or capacity below n returns `-2` without writes.

The domain keeps all updates integral and exactly representable in both TSVC float and double variants. It makes the repeated source loop observable while bounding the profile to eight passes. The pinned source initializer sets A to one and B/C to reciprocals; arrays are explicit inputs here, including signed values that exercise the comparison. Timing and the source's `4*ntimes` repetition count are outside this bounded operation profile.

This differs from s271's fixed `B[i] > 0` mask: s2712 tests A against B and can change its mask after an update. s2711 uses `B[i] != 0`, so it is a related branch-mask sibling, not an exact duplicate of either profile.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, function s2712 lines 3056–3081 and initializer s2712 lines 535–538; launcher family `TSVC/ControlFlow-dbl` and `TSVC/ControlFlow-flt`. The source comments attribute these codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found in the reviewed pinned materials. The ports are clean-room and reuse no upstream implementation text or comments; see `LICENSE.txt`.

The independent oracle is [`benchmarks/tsvc_s2712_comparison_gated_axpy_oracle.py`](../../tsvc_s2712_comparison_gated_axpy_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s2712_comparison_gated_axpy.c`](../../../c/t/tsvc_s2712_comparison_gated_axpy.c) |
| C3 | [`tsvc_s2712_comparison_gated_axpy.c3`](../../../c3/t/tsvc_s2712_comparison_gated_axpy.c3) |
| C++ | [`tsvc_s2712_comparison_gated_axpy.cpp`](../../../cpp/t/tsvc_s2712_comparison_gated_axpy.cpp) |
| Elisa | [`tsvc_s2712_comparison_gated_axpy.elisa`](../../../elisa/t/tsvc_s2712_comparison_gated_axpy.elisa) |
| Nim | [`tsvc_s2712_comparison_gated_axpy.nim`](../../../nim/t/tsvc_s2712_comparison_gated_axpy.nim) |
| Odin | [`tsvc_s2712_comparison_gated_axpy.odin`](../../../odin/t/tsvc_s2712_comparison_gated_axpy.odin) |
| Rust | [`tsvc_s2712_comparison_gated_axpy.rs`](../../../rust/t/tsvc_s2712_comparison_gated_axpy.rs) |
| V | [`tsvc_s2712_comparison_gated_axpy.v`](../../../v/t/tsvc_s2712_comparison_gated_axpy.v) |
| Zig | [`tsvc_s2712_comparison_gated_axpy.zig`](../../../zig/t/tsvc_s2712_comparison_gated_axpy.zig) |
