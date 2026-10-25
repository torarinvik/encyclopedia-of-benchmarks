# TSVC s251 scalar square expansion

This package is a bounded clean-room profile of TSVC `s251` from the
`Expansion-dbl` family. Each loop iteration expands a scalar expression into a
per-element square:

```text
s = B[i] + C[i] * D[i]
A[i] = s * s
```

The scalar temporary is local to each element; this is not a running
accumulator. A is overwritten, while B, C, and D remain unchanged.

## Contract

The exported symbol is `tsvc_s251_scalar_square_expansion`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, B[n], C[n], D[n]]`, with `n` in 1 through 64 and
  `passes` in 1 through 8.
- All array values are in `[-2,2]`.
- For each pass and ascending i, compute `s=B[i]+C[i]*D[i]`, then set
  `A[i]=s*s`.
- On success, output A as little-endian signed i64 values and return `n`.
- Malformed input returns `-1`; null output or capacity below `8*n` bytes
  returns `-2` without writing output.

The bounded scalar lies in `[-6,6]`, so squared results are in `[0,36]` and
exact in the source's binary64 `TYPE`. Since B/C/D are unchanged, later passes
produce the same A values; the pass field records a bounded repeat count for
the source loop. The source launcher initializes B to one and C/D to
reciprocals; the workload also includes varied integer values. Timing and
checker code are outside the package.

This map differs from s1244's polynomial with multiple terms and neighbor
output, s241's cross-coupled multi-array product, and s442's indexed square
accumulation. It does not reduce or scatter its squared values.

## Source and rights

The behavior reference is `s251` in `TSVC/tsc.inc`, lines 2316–2340, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2316). The loop is at lines 2328–2333. The
[`Expansion-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/tsc.c)
selects double precision; its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/info.sh)
uses run options `4160 14`. TSVC comments attribute its non-four-digit
codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for
Vectorizing Compilers*.

No explicit upstream license grant was found in the pinned source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream code or comments. No upstream license or endorsement is
claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s251_scalar_square_expansion_oracle.py`](../../tsvc_s251_scalar_square_expansion_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s251_scalar_square_expansion.c`](../../../c/t/tsvc_s251_scalar_square_expansion.c) |
| C3 | [`tsvc_s251_scalar_square_expansion.c3`](../../../c3/t/tsvc_s251_scalar_square_expansion.c3) |
| C++ | [`tsvc_s251_scalar_square_expansion.cpp`](../../../cpp/t/tsvc_s251_scalar_square_expansion.cpp) |
| Elisa | [`tsvc_s251_scalar_square_expansion.elisa`](../../../elisa/t/tsvc_s251_scalar_square_expansion.elisa) |
| Nim | [`tsvc_s251_scalar_square_expansion.nim`](../../../nim/t/tsvc_s251_scalar_square_expansion.nim) |
| Odin | [`tsvc_s251_scalar_square_expansion.odin`](../../../odin/t/tsvc_s251_scalar_square_expansion.odin) |
| Rust | [`tsvc_s251_scalar_square_expansion.rs`](../../../rust/t/tsvc_s251_scalar_square_expansion.rs) |
| V | [`tsvc_s251_scalar_square_expansion.v`](../../../v/t/tsvc_s251_scalar_square_expansion.v) |
| Zig | [`tsvc_s251_scalar_square_expansion.zig`](../../../zig/t/tsvc_s251_scalar_square_expansion.zig) |
