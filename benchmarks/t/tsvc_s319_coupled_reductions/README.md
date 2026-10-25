# TSVC s319 coupled reductions

This package is a bounded clean-room profile of TSVC `s319` from the
`Reductions-dbl` launcher family. Each ascending input index computes two
pointwise sums and folds both into one scalar total:

```text
a[i] = c[i] + d[i]
total += a[i]
b[i] = c[i] + e[i]
total += b[i]
```

The output contains final A, final B, then the combined total. This preserves
the fused source operation as one pass. It is distinct from `s313`'s dot
product and from ordinary array sums: `s319` produces two mapped vectors and
reduces both in the same loop. It also differs from `s152`, which accumulates
a product of three coefficient arrays into A without a coupled reduction.

## Contract

The exported symbol is `tsvc_s319_coupled_reductions`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, c[n], d[n], e[n]]`, with `n` in `1..64`.
- Each input value is in `[-2, 2]`.
- For ascending `i`, compute A and B as shown and add each result to `total`.
- Output `[A[n], B[n], total]` as little-endian signed i64 values and return
  `2*n + 1`.
- Output capacity must be at least `8*(2*n+1)` bytes. Invalid input returns
  `-1`; null output or insufficient capacity returns `-2`. Errors write no
  output.

Every A/B result is in `[-4,4]` and the total is in `[-512,512]`. These bounds
keep the integer profile exact in the source binary64 type and safely within
i64.

## Source and rights

The behavior reference is `s319` at lines 3613–3641 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3613)
in LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/Reductions-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Reductions-dbl/tsc.c),
which selects `TYPE double` and the reductions family. Source initialization
is at `TSVC/tsc.inc` lines 577–582; this bounded profile accepts C, D, and E
values from the caller so the coupled updates vary across indices. The TSVC
source comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded loop
contract and reuse no upstream source code or comments; no upstream license or
endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle and fixed workload are
[`tsvc_s319_coupled_reductions_oracle.py`](../../tsvc_s319_coupled_reductions_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s319_coupled_reductions.c`](../../../c/t/tsvc_s319_coupled_reductions.c) |
| C3 | [`tsvc_s319_coupled_reductions.c3`](../../../c3/t/tsvc_s319_coupled_reductions.c3) |
| C++ | [`tsvc_s319_coupled_reductions.cpp`](../../../cpp/t/tsvc_s319_coupled_reductions.cpp) |
| Elisa | [`tsvc_s319_coupled_reductions.elisa`](../../../elisa/t/tsvc_s319_coupled_reductions.elisa) |
| Nim | [`tsvc_s319_coupled_reductions.nim`](../../../nim/t/tsvc_s319_coupled_reductions.nim) |
| Odin | [`tsvc_s319_coupled_reductions.odin`](../../../odin/t/tsvc_s319_coupled_reductions.odin) |
| Rust | [`tsvc_s319_coupled_reductions.rs`](../../../rust/t/tsvc_s319_coupled_reductions.rs) |
| V | [`tsvc_s319_coupled_reductions.v`](../../../v/t/tsvc_s319_coupled_reductions.v) |
| Zig | [`tsvc_s319_coupled_reductions.zig`](../../../zig/t/tsvc_s319_coupled_reductions.zig) |
