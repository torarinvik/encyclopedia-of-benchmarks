# TSVC s271 positive-branch AXPY

This package is a bounded clean-room profile of TSVC `s271` from the
`ControlFlow-dbl` family. For each pass and ascending index, a strictly positive
B value selects an in-place A update:

```text
if B[i] > 0:
    A[i] += B[i] * C[i]
```

The predicate is based on an unchanged input array, so each index follows the
same branch on every pass. A is the only modified array.

## Contract

The exported symbol is `tsvc_s271_positive_branch_axpy`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, A[n], B[n], C[n]]`, with `n` in 1 through 64 and
  `passes` in 1 through 8.
- All array values are in `[-2,2]`.
- For every pass and ascending i, if `B[i] > 0`, update
  `A[i] += B[i] * C[i]`.
- On success, output final A as little-endian signed i64 values and return `n`.
- Malformed input returns `-1`; null output or capacity below `8*n` bytes
  returns `-2` without writing output.

The bounded values keep each result within `[-34,34]`, so all intermediate
arithmetic is exact in the source's binary64 `TYPE` and fits signed i64. The
source launcher initializes A to one and B/C to reciprocal squares, making its
default B predicate positive at every index. The package also accepts mixed
positive, zero, and negative B values to make the strict branch boundary
observable. Timing and checker code are outside the package.

This is distinct from s272, which uses an independent E threshold and updates
two arrays; s273–s278 use dependent or scalar-carried branches; s124 selects a
branch value inside an FMA expression; and `vif` performs a masked assignment
instead of an arithmetic accumulation.

## Source and rights

The behavior reference is `s271` in `TSVC/tsc.inc`, lines 2659–2683, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2659). The loop is at lines 2670–2676; the initializer selects A=1 and reciprocal-square B/C at lines 472–475. The
[`ControlFlow-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c)
selects double precision. Its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/info.sh)
uses run options `2325 14`. TSVC comments attribute its non-four-digit
codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for
Vectorizing Compilers*.

No explicit upstream license grant was found in the pinned source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream code or comments. No upstream license or endorsement is
claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s271_positive_branch_axpy_oracle.py`](../../tsvc_s271_positive_branch_axpy_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s271_positive_branch_axpy.c`](../../../c/t/tsvc_s271_positive_branch_axpy.c) |
| C3 | [`tsvc_s271_positive_branch_axpy.c3`](../../../c3/t/tsvc_s271_positive_branch_axpy.c3) |
| C++ | [`tsvc_s271_positive_branch_axpy.cpp`](../../../cpp/t/tsvc_s271_positive_branch_axpy.cpp) |
| Elisa | [`tsvc_s271_positive_branch_axpy.elisa`](../../../elisa/t/tsvc_s271_positive_branch_axpy.elisa) |
| Nim | [`tsvc_s271_positive_branch_axpy.nim`](../../../nim/t/tsvc_s271_positive_branch_axpy.nim) |
| Odin | [`tsvc_s271_positive_branch_axpy.odin`](../../../odin/t/tsvc_s271_positive_branch_axpy.odin) |
| Rust | [`tsvc_s271_positive_branch_axpy.rs`](../../../rust/t/tsvc_s271_positive_branch_axpy.rs) |
| V | [`tsvc_s271_positive_branch_axpy.v`](../../../v/t/tsvc_s271_positive_branch_axpy.v) |
| Zig | [`tsvc_s271_positive_branch_axpy.zig`](../../../zig/t/tsvc_s271_positive_branch_axpy.zig) |
