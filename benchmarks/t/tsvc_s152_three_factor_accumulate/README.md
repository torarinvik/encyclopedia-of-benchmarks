# TSVC s152 three-factor accumulation

This package implements a bounded clean-room profile of TSVC `s152` from the
`GlobalDataFlow-dbl` family. For each index, the source first computes
`temporary = d[i] * e[i]` and then applies `a[i] += temporary * c[i]`. Each
index is independent; the helper call in the source does not add cross-index
state. The package exposes the repeated update count as a bounded `passes`
input.

This is distinct from the local EDN Q15 vector multiply-add: EDN applies a
single two-vector product with a fixed-point shift, while s152 accumulates a
three-array product in the source's binary64 profile. It also differs from
TSVC `s273`, which applies a two-factor update with a dependent branch and
updates additional arrays, and from `vbor`, which calculates nested products
then reduces them to one scalar.

## Contract

The exported symbol is `tsvc_s152_three_factor_accumulate`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, a[n], c[n], d[n], e[n]]`, with `n` in `1..64` and
  `passes` in `1..32`.
- Every value is in `[-2,2]`. Products and the repeated accumulations remain
  exact integers in binary64 and fit signed i64.
- In each pass, visit `i` upward, compute `temporary = d[i]*e[i]`, then apply
  `a[i] += temporary*c[i]`. The `c`, `d`, and `e` arrays are read-only.
- Input is unchanged. On success, the final `a` vector is emitted as
  little-endian signed i64 values and the function returns `n`.
- Malformed input returns `-1`. Null output or capacity below `8*n` returns
  `-2`; validation happens first and errors write no output.

The bounded integer domain retains the source's double-precision arithmetic
exactly. Timing-loop and dummy-call scaffolding are outside the profile.

## Source and rights

The behavior reference is `s152` and helper `s152s` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1536)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`TSVC/GlobalDataFlow-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/GlobalDataFlow-dbl/tsc.c),
which selects `TYPE double` and global-data-flow codelets. The source
initializes `a` to one, `b` to zero, and `c`, `d`, and `e` to small reciprocal
values; this package takes bounded caller inputs instead. The TSVC source
attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*. No explicit license
grant was found in the pinned source or repository material reviewed. These
ports independently implement the bounded mathematical loop, reuse no
upstream source or comments, and claim no upstream license or endorsement.
See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and cases are
[`tsvc_s152_three_factor_accumulate_oracle.py`](../../tsvc_s152_three_factor_accumulate_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s152_three_factor_accumulate.c`](../../../c/t/tsvc_s152_three_factor_accumulate.c) |
| C3 | [`tsvc_s152_three_factor_accumulate.c3`](../../../c3/t/tsvc_s152_three_factor_accumulate.c3) |
| C++ | [`tsvc_s152_three_factor_accumulate.cpp`](../../../cpp/t/tsvc_s152_three_factor_accumulate.cpp) |
| Elisa | [`tsvc_s152_three_factor_accumulate.elisa`](../../../elisa/t/tsvc_s152_three_factor_accumulate.elisa) |
| Nim | [`tsvc_s152_three_factor_accumulate.nim`](../../../nim/t/tsvc_s152_three_factor_accumulate.nim) |
| Odin | [`tsvc_s152_three_factor_accumulate.odin`](../../../odin/t/tsvc_s152_three_factor_accumulate.odin) |
| Rust | [`tsvc_s152_three_factor_accumulate.rs`](../../../rust/t/tsvc_s152_three_factor_accumulate.rs) |
| V | [`tsvc_s152_three_factor_accumulate.v`](../../../v/t/tsvc_s152_three_factor_accumulate.v) |
| Zig | [`tsvc_s152_three_factor_accumulate.zig`](../../../zig/t/tsvc_s152_three_factor_accumulate.zig) |
