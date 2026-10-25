# TSVC vbor nested-product kernel

This package isolates the `vbor` loop from the pending TSVC `ControlLoops-dbl`
launcher. It evaluates the source's four nested products for each of six
corresponding array values, multiplies those products, and returns their sum.
The current local algorithms cover vector addition, products, and reductions,
but not this source-specific nested-product polynomial.

## Contract

The ABI is `tsvc_vbor` with `i64_array_scalar_call` framing:

- Input: `[n, A[0..n), B[0..n), C[0..n), D[0..n), E[0..n), F[0..n)]`.
- `n` is in `1..128`; the exact input length is `1 + 6*n`.
- All six arrays contain values in `0..2`; malformed input returns `-1`.
- For each ascending index, the source calculates `a1` as A times the sum of
  the ten pairwise products among B through F; `b1` as B times the six pairwise
  products among C through F; `c1` as C times the three pairwise products
  among D through F; and `d1 = D*E*F`. The output is the sum of `a1*b1*c1*d1`.
- Input is preserved. The maximum checksum for `n=128` is 94,371,840.

The source uses `double`. Values in this bounded contract and every intermediate
are integers well below 2^53, so they are represented exactly in binary64; the
ports use signed 64-bit integer operations with identical results.

## Source and rights

The source is `vbor` in
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L5497)
at pinned LAC-DCC Benchmarks commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; it is included by
[`TSVC/ControlLoops-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlLoops-dbl/tsc.c).
The launcher is
[`TSVC/ControlLoops-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlLoops-dbl/info.sh),
which compiles `dummy.c` and `tsc.c` with `-std=gnu99` and invokes the suite
with `1640 14`. This package measures one bounded codelet invocation and omits
the launcher's timing harness, repeated passes, and dummy calls.

The TSVC source comment attributes the non-four-digit codelets to David
Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*. The pinned source and repository material reviewed do not state an
explicit license grant. These ports are independent implementations of the
documented loop behavior and reuse no upstream source text or comments. No
upstream license or endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt)
for the rights note.

## Workload and oracle

[`workload.json`](workload.json) contains source-shaped constant cases, a zero
factor, and malformed-input cases. The independent integer oracle is
[`tsvc_vbor_oracle.py`](../../tsvc_vbor_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_vbor.c`](../../../c/t/tsvc_vbor.c) |
| C3 | [`tsvc_vbor.c3`](../../../c3/t/tsvc_vbor.c3) |
| C++ | [`tsvc_vbor.cpp`](../../../cpp/t/tsvc_vbor.cpp) |
| Elisa | [`tsvc_vbor.elisa`](../../../elisa/t/tsvc_vbor.elisa) |
| Nim | [`tsvc_vbor.nim`](../../../nim/t/tsvc_vbor.nim) |
| Odin | [`tsvc_vbor.odin`](../../../odin/t/tsvc_vbor.odin) |
| Rust | [`tsvc_vbor.rs`](../../../rust/t/tsvc_vbor.rs) |
| V | [`tsvc_vbor.v`](../../../v/t/tsvc_vbor.v) |
| Zig | [`tsvc_vbor.zig`](../../../zig/t/tsvc_vbor.zig) |
