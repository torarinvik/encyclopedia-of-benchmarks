# TSVC s441/s443 D-sign branch updates

This package covers two related but nonidentical TSVC ControlFlow codelets selected by a mode field. Mode 0 profiles s441: for each index, D<0 adds B*C to A, D==0 adds B², and D>0 adds C². Mode 1 profiles s443: D<=0 adds B*C, while D>0 adds B². Both visit indices in ascending order and repeat the full sweep for each pass.

## Contract

- Exported symbol: `tsvc_s441_s443_d_sign_branch_updates`; ABI: `float64_slice_io`.
- Input is `[mode,n,passes,A[n],B[n],C[n],D[n]]`; mode is 0 (s441) or 1 (s443), `1 <= n <= 64`, `1 <= passes <= 8`, and length is exactly `3+4*n`.
- Values are finite integer-valued binary64 values in `[-1,1]`.
- Output is final A in index order, count `n`; input is unchanged.
- Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes.
- Each selected increment is in `[-1,1]`; A stays within `[-9,9]`, exactly representable in binary32 and binary64.

These profiles are related to s442's value-selection branch family, but s441/s443 select arithmetic using the sign of D and use different products. Mode 0 preserves the distinct D==0 arm; mode 1 folds zero into its D<=0 arm.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`: s441 lines 4604–4633 and initializer lines 690–696; s443 lines 4682–4716 and initializer lines 703–706. Both codelets are called by the pinned `ControlFlow-dbl` and `ControlFlow-flt` test drivers. TSVC source comments attribute codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found in reviewed pinned materials; these are clean-room ports. See `LICENSE.txt`.

The independent oracle is [`benchmarks/tsvc_s441_s443_d_sign_branch_updates_oracle.py`](../../tsvc_s441_s443_d_sign_branch_updates_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s441_s443_d_sign_branch_updates.c`](../../../c/t/tsvc_s441_s443_d_sign_branch_updates.c) |
| C3 | [`tsvc_s441_s443_d_sign_branch_updates.c3`](../../../c3/t/tsvc_s441_s443_d_sign_branch_updates.c3) |
| C++ | [`tsvc_s441_s443_d_sign_branch_updates.cpp`](../../../cpp/t/tsvc_s441_s443_d_sign_branch_updates.cpp) |
| Elisa | [`tsvc_s441_s443_d_sign_branch_updates.elisa`](../../../elisa/t/tsvc_s441_s443_d_sign_branch_updates.elisa) |
| Nim | [`tsvc_s441_s443_d_sign_branch_updates.nim`](../../../nim/t/tsvc_s441_s443_d_sign_branch_updates.nim) |
| Odin | [`tsvc_s441_s443_d_sign_branch_updates.odin`](../../../odin/t/tsvc_s441_s443_d_sign_branch_updates.odin) |
| Rust | [`tsvc_s441_s443_d_sign_branch_updates.rs`](../../../rust/t/tsvc_s441_s443_d_sign_branch_updates.rs) |
| V | [`tsvc_s441_s443_d_sign_branch_updates.v`](../../../v/t/tsvc_s441_s443_d_sign_branch_updates.v) |
| Zig | [`tsvc_s441_s443_d_sign_branch_updates.zig`](../../../zig/t/tsvc_s441_s443_d_sign_branch_updates.zig) |
