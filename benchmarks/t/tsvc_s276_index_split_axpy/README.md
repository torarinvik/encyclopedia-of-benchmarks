# TSVC s276 index-split AXPY

This package is a bounded clean-room profile of TSVC `s276` from the
`ControlFlow-dbl` family. It uses the loop index to choose one of two
coefficients, then accumulates a product into A:

```text
mid = floor(n / 2)
for i in ascending order:
    if i + 1 < mid:
        A[i] += B[i] * C[i]
    else:
        A[i] += B[i] * D[i]
```

The cutoff reproduces the source's `i+1 < mid` test. With even `n=64`, the
C branch handles indices 0 through 30; index 31 and later use D. Both the
predicate and chosen coefficient are independent of array values.

## Contract

The exported symbol is `tsvc_s276_index_split_axpy`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, A[n], B[n], C[n], D[n]]`, with `n` in 1 through 64
  and `passes` in 1 through 8.
- All array values are in `[-2,2]`.
- For every pass and ascending i, use C when `i+1 < floor(n/2)`, otherwise
  use D, and update `A[i] += B[i] * coefficient[i]`.
- On success, output final A as little-endian signed i64 values and return `n`.
- Malformed input returns `-1`; null output or capacity below `8*n` bytes
  returns `-2` without writing output.

At most eight passes keep every result in `[-34,34]`, so all intermediates are
exact in the source's binary64 `TYPE` and fit signed i64. The upstream
initializer uses A=1 and reciprocal B/C/D arrays; this bounded integer profile
retains the index-derived control split while allowing exact, varied inputs.
The launcher repeats the kernel for timing; repetition and checker code are
outside the package.

This differs from s271's positive-B mask, s272's E-threshold, and s273/s274/s278
data-dependent control flow. It also differs from s124's conditional FMA
selection: s276 selects the multiplier solely by the loop index and accumulates
into A on both branches.

## Source and rights

The behavior reference is `s276` in `TSVC/tsc.inc`, lines 2829–2856, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2829). The loop is at lines 2840–2849; the
[`ControlFlow-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c)
selects double precision, and its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/info.sh)
uses run options `2325 14`. TSVC comments attribute its non-four-digit
codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for
Vectorizing Compilers*.

No explicit upstream license grant was found in the pinned source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream code or comments. No upstream license or endorsement is
claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s276_index_split_axpy_oracle.py`](../../tsvc_s276_index_split_axpy_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s276_index_split_axpy.c`](../../../c/t/tsvc_s276_index_split_axpy.c) |
| C3 | [`tsvc_s276_index_split_axpy.c3`](../../../c3/t/tsvc_s276_index_split_axpy.c3) |
| C++ | [`tsvc_s276_index_split_axpy.cpp`](../../../cpp/t/tsvc_s276_index_split_axpy.cpp) |
| Elisa | [`tsvc_s276_index_split_axpy.elisa`](../../../elisa/t/tsvc_s276_index_split_axpy.elisa) |
| Nim | [`tsvc_s276_index_split_axpy.nim`](../../../nim/t/tsvc_s276_index_split_axpy.nim) |
| Odin | [`tsvc_s276_index_split_axpy.odin`](../../../odin/t/tsvc_s276_index_split_axpy.odin) |
| Rust | [`tsvc_s276_index_split_axpy.rs`](../../../rust/t/tsvc_s276_index_split_axpy.rs) |
| V | [`tsvc_s276_index_split_axpy.v`](../../../v/t/tsvc_s276_index_split_axpy.v) |
| Zig | [`tsvc_s276_index_split_axpy.zig`](../../../zig/t/tsvc_s276_index_split_axpy.zig) |
