# TSVC s279 nested-branch recomputation

This package is a bounded clean-room profile of TSVC `s279` from the
`ControlFlow-dbl` family. Each position follows one of two source-ordered
paths, then recomputes A from the current B and C values:

```text
if A[i] > 0:
    C[i] = -C[i] + E[i] * E[i]
else:
    B[i] = -B[i] + D[i] * D[i]
    if B[i] > A[i]:
        C[i] += D[i] * E[i]
A[i] = B[i] + C[i] * D[i]
```

The nested comparison is strict. The second test uses the newly assigned B and
the previous A; A is overwritten only after the branch path completes. On
subsequent passes, this recomputed A selects the outer branch.

## Contract

The exported symbol is `tsvc_s279_nested_branch_recompute`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, A[n], B[n], C[n], D[n], E[n]]`, with `n` in 1 through
  64 and `passes` in 1 through 8.
- All input array values are in `[-2,2]`.
- For every pass, visit each i in ascending order, apply the branch sequence
  above, and retain the updated A/B/C state for the next pass.
- On success, output final A followed by final B followed by final C as
  little-endian signed i64 values and return `3*n`.
- Malformed input returns `-1`; null output or capacity below `24*n` bytes
  returns `-2` without writing output.

With at most eight passes, B stays in `[-2,6]`, C stays within `[-34,34]`,
and the final A is within `[-74,74]`. The bounded integer operations are exact
in the source's binary64 `TYPE` and fit signed i64. The upstream initializer
uses fractional C/D/E data and mixed-sign A/B vectors; this profile uses small
integers to expose all nested branches while keeping cross-language results
exact. The launcher repetition and checker are outside the package.

This is distinct from s278, which has one A-controlled update to B or C and a
common recomputation; s279 has a nested second comparison, an `A<=0` branch
that may mutate both B and C, and its `A>0` branch mutates C using E squared.
It also differs from s273/s274, whose dependencies and branch assignments are
different.

## Source and rights

The behavior reference is `s279` in `TSVC/tsc.inc`, lines 2927–2960, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2927). The ordered loop is at lines 2937–2952. The
[`ControlFlow-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c)
selects double precision; its [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/info.sh)
uses run options `2325 14`. TSVC comments attribute its non-four-digit
codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for
Vectorizing Compilers*.

No explicit upstream license grant was found in the pinned source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream code or comments. No upstream license or endorsement is
claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s279_nested_branch_recompute_oracle.py`](../../tsvc_s279_nested_branch_recompute_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s279_nested_branch_recompute.c`](../../../c/t/tsvc_s279_nested_branch_recompute.c) |
| C3 | [`tsvc_s279_nested_branch_recompute.c3`](../../../c3/t/tsvc_s279_nested_branch_recompute.c3) |
| C++ | [`tsvc_s279_nested_branch_recompute.cpp`](../../../cpp/t/tsvc_s279_nested_branch_recompute.cpp) |
| Elisa | [`tsvc_s279_nested_branch_recompute.elisa`](../../../elisa/t/tsvc_s279_nested_branch_recompute.elisa) |
| Nim | [`tsvc_s279_nested_branch_recompute.nim`](../../../nim/t/tsvc_s279_nested_branch_recompute.nim) |
| Odin | [`tsvc_s279_nested_branch_recompute.odin`](../../../odin/t/tsvc_s279_nested_branch_recompute.odin) |
| Rust | [`tsvc_s279_nested_branch_recompute.rs`](../../../rust/t/tsvc_s279_nested_branch_recompute.rs) |
| V | [`tsvc_s279_nested_branch_recompute.v`](../../../v/t/tsvc_s279_nested_branch_recompute.v) |
| Zig | [`tsvc_s279_nested_branch_recompute.zig`](../../../zig/t/tsvc_s279_nested_branch_recompute.zig) |
