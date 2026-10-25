# TSVC s2101 diagonal matrix FMA

This package implements a bounded, clean-room profile of TSVC `s2101` from
the `CrossingThresholds-dbl` launcher family. It updates only the main
diagonal of a row-major matrix:

```text
AA[i,i] = AA[i,i] + BB[i,i] * CC[i,i]
```

All off-diagonal `AA` entries remain unchanged. This diagonal-stride traversal
is distinct from `tsvc_s125_matrix_flattened_fma`, which performs the same
elementwise operation across every matrix cell, and from
`tsvc_s141_packed_symmetric_update`, which adds a dense lower triangle into a
packed destination without products.

## Contract

The exported symbol is `tsvc_s2101_diagonal_matrix_fma`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, AA[n*n], BB[n*n], CC[n*n]]`; each matrix is row-major.
- `n` is 1 through 8 and all matrix values are in `[-100, 100]`.
- One ascending diagonal sweep computes `AA[i*n+i] += BB[i*n+i] * CC[i*n+i]`.
- Output is the full final `AA` matrix as little-endian signed i64 values;
  success returns `n*n` and writes `8*n*n` bytes. Input is unchanged.
- Malformed input returns `-1`; a null output or insufficient capacity
  returns `-2` without writing output.

The bounds keep every product and sum exactly representable in the source's
binary64 `TYPE` and within signed i64. The profile measures one sweep and
excludes TSVC's timing repetitions, initializer, dummy calls, and checker.

## Source and rights

The behavior reference is `s2101` in `TSVC/tsc.inc`, lines 3230–3253; its
diagonal update is at lines 3242–3245. The source is pinned to LAC-DCC
`Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3230). The launcher file
[`TSVC/CrossingThresholds-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/CrossingThresholds-dbl/tsc.c)
selects `TYPE double`. TSVC comments attribute its non-four-digit codelets to
David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement the bounded diagonal
update and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s2101_diagonal_matrix_fma_oracle.py`](../../tsvc_s2101_diagonal_matrix_fma_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s2101_diagonal_matrix_fma.c`](../../../c/t/tsvc_s2101_diagonal_matrix_fma.c) |
| C3 | [`tsvc_s2101_diagonal_matrix_fma.c3`](../../../c3/t/tsvc_s2101_diagonal_matrix_fma.c3) |
| C++ | [`tsvc_s2101_diagonal_matrix_fma.cpp`](../../../cpp/t/tsvc_s2101_diagonal_matrix_fma.cpp) |
| Elisa | [`tsvc_s2101_diagonal_matrix_fma.elisa`](../../../elisa/t/tsvc_s2101_diagonal_matrix_fma.elisa) |
| Nim | [`tsvc_s2101_diagonal_matrix_fma.nim`](../../../nim/t/tsvc_s2101_diagonal_matrix_fma.nim) |
| Odin | [`tsvc_s2101_diagonal_matrix_fma.odin`](../../../odin/t/tsvc_s2101_diagonal_matrix_fma.odin) |
| Rust | [`tsvc_s2101_diagonal_matrix_fma.rs`](../../../rust/t/tsvc_s2101_diagonal_matrix_fma.rs) |
| V | [`tsvc_s2101_diagonal_matrix_fma.v`](../../../v/t/tsvc_s2101_diagonal_matrix_fma.v) |
| Zig | [`tsvc_s2101_diagonal_matrix_fma.zig`](../../../zig/t/tsvc_s2101_diagonal_matrix_fma.zig) |
