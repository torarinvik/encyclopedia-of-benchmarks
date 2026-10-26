# TSVC s222 interleaved square recurrence

This package models one ascending pass of TSVC s222's interleaved statements.
For each `i` from 1 through `n-1`, it adds `B[i]*C[i]` to `A[i]`, sets
`E[i] = E[i-1]*E[i-1]`, then subtracts the same product from `A[i]`. The
bounded integer domain makes the add/subtract pair exact, while the E update
retains the source's nonlinear recurrence and statement order. The result
contains final A followed by final E.

The profile is distinct from s211/s212 neighbor updates and s321/s322 linear
recurrences. It is also distinct from s317's fixed-operand product reduction;
s317 itself is treated as the constant-factor specialization of the already
represented s312 array-product reduction.

The pinned initializer leaves E at static zero, which makes the square
recurrence unobservable in the launcher default. This bounded source-shaped
profile supplies the E seed explicitly so the recurrence can be exercised;
it does not claim that the launcher uses these custom seed values.

## Contract

The exported symbol is `tsvc_s222_interleaved_square_recurrence`, using the
`float64_slice_io` ABI. Input is `[n, A[n], B[n], C[n], E[n]]` with `1 <= n <=
64`. A, B, and C values are integers in `[-2,2]`; E values are selected from
`{-1,-0.5,0,0.5,1}`. E[0] seeds the recurrence; later initial E entries are
validated but overwritten. The output is `[A_final[n], E_final[n]]` as
binary64 values. Invalid input returns `-1`; null output or capacity below
`2*n` returns `-2`, after validation. Errors write no output and input is not
modified.

The workload uses one source-loop pass. It excludes TSVC timing repetitions,
dummy calls, and other initialization helpers. The exact finite seed set keeps the
recurrence exactly representable and produces identical values for the
binary32 and binary64 source variants.

## Source and rights

Behavior is pinned to `s222` in `TSVC/tsc.inc` at lines 1961–1985, selected by
`TSVC/StatementReordering-dbl/tsc.c` and its float counterpart. The pinned
launchers use `20000 14` and `20000 5`, respectively. The TSVC comments
attribute these codelets to David Callahan, Jack Dongarra, and David Levine.
No explicit upstream redistribution grant was found; these ports are clean
room and make no upstream license claim. See [LICENSE.txt](LICENSE.txt).

The independent oracle and fixtures are in
[`workload.json`](workload.json) and
[`benchmarks/tsvc_s222_interleaved_square_recurrence_oracle.py`](../../tsvc_s222_interleaved_square_recurrence_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s222_interleaved_square_recurrence.c`](../../../c/t/tsvc_s222_interleaved_square_recurrence.c) |
| C3 | [`tsvc_s222_interleaved_square_recurrence.c3`](../../../c3/t/tsvc_s222_interleaved_square_recurrence.c3) |
| C++ | [`tsvc_s222_interleaved_square_recurrence.cpp`](../../../cpp/t/tsvc_s222_interleaved_square_recurrence.cpp) |
| Elisa | [`tsvc_s222_interleaved_square_recurrence.elisa`](../../../elisa/t/tsvc_s222_interleaved_square_recurrence.elisa) |
| Nim | [`tsvc_s222_interleaved_square_recurrence.nim`](../../../nim/t/tsvc_s222_interleaved_square_recurrence.nim) |
| Odin | [`tsvc_s222_interleaved_square_recurrence.odin`](../../../odin/t/tsvc_s222_interleaved_square_recurrence.odin) |
| Rust | [`tsvc_s222_interleaved_square_recurrence.rs`](../../../rust/t/tsvc_s222_interleaved_square_recurrence.rs) |
| V | [`tsvc_s222_interleaved_square_recurrence.v`](../../../v/t/tsvc_s222_interleaved_square_recurrence.v) |
| Zig | [`tsvc_s222_interleaved_square_recurrence.zig`](../../../zig/t/tsvc_s222_interleaved_square_recurrence.zig) |
