# TSVC s1251 per-element dual update

This package profiles the Expansion-family `s1251` loop. For each position it saves `B[i]+C[i]`, writes `B[i]=A[i]+D[i]`, then writes `A[i]=(B_old[i]+C[i])*E[i]`. The saved temporary and the source statement order make the two outputs observable.

## Contract

The exported symbol is `tsvc_s1251_per_element_dual_update`, using `float64_slice_io`.

- Input is `[n,A[n],B[n],C[n],D[n],E[n]]`; `n` is 1 through 64 and length is exactly `1+5*n`.
- Every value is a finite integer-valued binary64 number in `[-1,1]`.
- Process indices in ascending order. Save `tmp=B[i]+C[i]`, then set `B[i]=A[i]+D[i]`, then set `A[i]=tmp*E[i]`.
- Return `[A_final[n],B_final[n]]` and result count `2*n`. Input is unchanged.
- Invalid input returns `-1`; null output or capacity below `2*n` returns `-2` without writes.

Each intermediate is in `[-2,2]` and exactly representable in both source precisions. The explicit arrays replace the pinned `init("s251 ")` state; timing repetitions, dummy call, and checker are excluded.

## Source and rights

Pinned source is `lac-dcc/Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, `s1251` lines 2342–2367, selected by `TSVC/Expansion-dbl/info.sh` and `TSVC/Expansion-flt/info.sh`. The kernel's local temporary preserves `B[i]+C[i]` before the B write. The source comments attribute its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine. No explicit upstream modification or redistribution grant was found; the ports are clean-room and claim no upstream license. See `LICENSE.txt`.

The independent oracle is [`benchmarks/tsvc_s1251_per_element_dual_update_oracle.py`](../../tsvc_s1251_per_element_dual_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s1251_per_element_dual_update.c`](../../../c/t/tsvc_s1251_per_element_dual_update.c) |
| C3 | [`tsvc_s1251_per_element_dual_update.c3`](../../../c3/t/tsvc_s1251_per_element_dual_update.c3) |
| C++ | [`tsvc_s1251_per_element_dual_update.cpp`](../../../cpp/t/tsvc_s1251_per_element_dual_update.cpp) |
| Elisa | [`tsvc_s1251_per_element_dual_update.elisa`](../../../elisa/t/tsvc_s1251_per_element_dual_update.elisa) |
| Nim | [`tsvc_s1251_per_element_dual_update.nim`](../../../nim/t/tsvc_s1251_per_element_dual_update.nim) |
| Odin | [`tsvc_s1251_per_element_dual_update.odin`](../../../odin/t/tsvc_s1251_per_element_dual_update.odin) |
| Rust | [`tsvc_s1251_per_element_dual_update.rs`](../../../rust/t/tsvc_s1251_per_element_dual_update.rs) |
| V | [`tsvc_s1251_per_element_dual_update.v`](../../../v/t/tsvc_s1251_per_element_dual_update.v) |
| Zig | [`tsvc_s1251_per_element_dual_update.zig`](../../../zig/t/tsvc_s1251_per_element_dual_update.zig) |
