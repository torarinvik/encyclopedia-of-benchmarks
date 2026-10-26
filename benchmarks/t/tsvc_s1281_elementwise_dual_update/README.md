# TSVC s1281 elementwise dual update

This package profiles the bounded arithmetic core of the pinned TSVC
CrossingThresholds `s1281` codelet. Each pass visits indices in ascending
order, computes `x = (B[i]*C[i] + A[i]*D[i]) + E[i]`, then writes `A[i]=x-1`
followed by `B[i]=x`. The stored A and B values are visible on later passes.

## Contract

- The exported symbol is `tsvc_s1281_elementwise_dual_update` with the
  `i64_array_bytes_output` ABI.
- Input is `[n,passes,A[n],B[n],C[n],D[n],E[n]]`, with `1<=n<=16`,
  `1<=passes<=8`, exact length `2+5*n`, and all array values in `[-1,1]`.
- Output is final A followed by final B, encoded as little-endian signed i64;
  successful result is `16*n` bytes.
- Invalid/null input returns `-1`. Null output or insufficient capacity
  returns `-2` without writes. Input is not modified.
- The pinned source selects `TYPE double` or `TYPE float` by launcher. This
  integer-valued bounded profile keeps the source-ordered intermediates exact
  in both formats, while preserving the expression grouping and write order.

The pinned codelet initializes through `init("s281 ")`, despite its `s1281`
name. This profile supplies an explicit bounded frame and models the s1281
loop body; it does not claim to reproduce that initializer's full benchmark
state or timing harness.

## Provenance and rights

Source: `lac-dcc/Benchmarks` at commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, s1281 lines
3264–3291, selected by the `CrossingThresholds-dbl` and `CrossingThresholds-flt`
launchers. The source comments attribute codelets to David Callahan, Jack
Dongarra, and David Levine. No explicit modification or redistribution grant
was found in the reviewed pinned materials; the ports are clean-room.
See [LICENSE.txt](LICENSE.txt).

The independent oracle is
[`benchmarks/tsvc_s1281_elementwise_dual_update_oracle.py`](../../tsvc_s1281_elementwise_dual_update_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [C port](../../../c/t/tsvc_s1281_elementwise_dual_update.c) |
| C3 | [C3 port](../../../c3/t/tsvc_s1281_elementwise_dual_update.c3) |
| C++ | [C++ port](../../../cpp/t/tsvc_s1281_elementwise_dual_update.cpp) |
| Elisa | [Elisa port](../../../elisa/t/tsvc_s1281_elementwise_dual_update.elisa) |
| Nim | [Nim port](../../../nim/t/tsvc_s1281_elementwise_dual_update.nim) |
| Odin | [Odin port](../../../odin/t/tsvc_s1281_elementwise_dual_update.odin) |
| Rust | [Rust port](../../../rust/t/tsvc_s1281_elementwise_dual_update.rs) |
| V | [V port](../../../v/t/tsvc_s1281_elementwise_dual_update.v) |
| Zig | [Zig port](../../../zig/t/tsvc_s1281_elementwise_dual_update.zig) |
