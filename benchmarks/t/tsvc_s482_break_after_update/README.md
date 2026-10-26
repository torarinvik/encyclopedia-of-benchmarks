# TSVC s482 break-after-update prefix sweep

This package profiles s482's ascending loop with an update before its break test. For each pass, visit `i` from zero upward, perform `A[i] += B[i]*C[i]`, then stop that pass if `C[i] > B[i]`. The stop test uses the unchanged B/C arrays and is strict; equality does not break. Each new pass starts again at index zero.

## Contract

- Exported symbol: `tsvc_s482_break_after_update`; ABI: `float64_slice_io`.
- Input is `[n,passes,A[n],B[n],C[n]]`, with `1 <= n <= 64`, `1 <= passes <= 8`, exact length `2+3*n`.
- Values are finite integer-valued binary64 values in `[-1,1]`.
- Output is final A in index order, count `n`. B and C are unchanged; input is not modified.
- Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writes.
- A stays within `[-513,513]`, exactly representable in binary32 and binary64.

The pinned initializer sets A to one and B/C to source fractions; this bounded contract makes all three arrays explicit. Unlike the local `tsvc_s332_first_above_threshold` scan, s482 mutates each visited A element before checking the stop predicate, then repeats the prefix sweep on later passes.

## Source and rights

Pinned source: `lac-dcc/Benchmarks`, commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, symbol `s482` (lines 4887–4911); it calls `init("s482 ")` (initializer case lines 728–731). It is selected by `TSVC/ControlFlow-dbl/info.sh` and `TSVC/ControlFlow-flt/info.sh`. TSVC comments attribute codelets to David Callahan, Jack Dongarra, and David Levine. No explicit modification or redistribution grant was found in reviewed pinned materials; these are clean-room ports. See `LICENSE.txt`.

The independent oracle is [`benchmarks/tsvc_s482_break_after_update_oracle.py`](../../tsvc_s482_break_after_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s482_break_after_update.c`](../../../c/t/tsvc_s482_break_after_update.c) |
| C3 | [`tsvc_s482_break_after_update.c3`](../../../c3/t/tsvc_s482_break_after_update.c3) |
| C++ | [`tsvc_s482_break_after_update.cpp`](../../../cpp/t/tsvc_s482_break_after_update.cpp) |
| Elisa | [`tsvc_s482_break_after_update.elisa`](../../../elisa/t/tsvc_s482_break_after_update.elisa) |
| Nim | [`tsvc_s482_break_after_update.nim`](../../../nim/t/tsvc_s482_break_after_update.nim) |
| Odin | [`tsvc_s482_break_after_update.odin`](../../../odin/t/tsvc_s482_break_after_update.odin) |
| Rust | [`tsvc_s482_break_after_update.rs`](../../../rust/t/tsvc_s482_break_after_update.rs) |
| V | [`tsvc_s482_break_after_update.v`](../../../v/t/tsvc_s482_break_after_update.v) |
| Zig | [`tsvc_s482_break_after_update.zig`](../../../zig/t/tsvc_s482_break_after_update.zig) |
