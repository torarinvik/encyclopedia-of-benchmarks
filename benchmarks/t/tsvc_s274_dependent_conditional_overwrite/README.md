# TSVC s274 dependent conditional overwrite

This package is a bounded clean-room profile of TSVC `s274` from the
`ControlFlow-dbl` family. At each ascending index, the loop first calculates a
new A value. The predicate uses that newly calculated value; the positive
branch updates B, while the other branch overwrites A with the D/E product:

```text
A[i] = C[i] + E[i] * D[i]
if A[i] > 0:
    B[i] = A[i] + B[i]
else:
    A[i] = D[i] * E[i]
```

For repeated passes, A is recomputed from C, D, and E before every branch.
B accumulates only on the positive path. C, D, and E are unchanged.

## Contract

The exported symbol is `tsvc_s274_dependent_conditional_overwrite`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, B[n], C[n], D[n], E[n]]`, with `n` in 1 through 64
  and `passes` in 1 through 8. Initial A is omitted because the source
  overwrites it before reading it.
- All packed array values are in `[-2,2]`.
- For each pass and ascending i, assign `A[i]=C[i]+E[i]*D[i]`. If this A is
  positive, assign `B[i]=A[i]+B[i]`; otherwise replace A with `D[i]*E[i]`.
- On success, output final A followed by final B as little-endian signed i64
  values and return `2*n`.
- Malformed input returns `-1`; null output or capacity below `16*n` bytes
  returns `-2` without writing output.

The temporary branch value stays within `[-6,6]`, the alternate A value within
`[-4,4]`, and B within `[-50,50]`. All operations are exact integers in the
source's binary64 `TYPE` and fit signed i64. The profile executes a bounded
number of loop sweeps and omits launcher timing, dummy calls, and checking.

This differs from s273's update-then-negative-test sequence, which can update
B and then always updates C, and from s278's prior-A branch selecting between
B/C updates before a common A recomputation. Here A is recomputed first and
then either B is updated or A itself is overwritten.

## Source and rights

The behavior reference is `s274` in `TSVC/tsc.inc`, lines 2745–2771, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2745). The
[`ControlFlow-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c)
selects double precision. TSVC comments attribute its non-four-digit codelets
to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*.

No explicit upstream license grant was found in the pinned source or
repository material reviewed. These ports independently implement the bounded
behavior and reuse no upstream code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s274_dependent_conditional_overwrite_oracle.py`](../../tsvc_s274_dependent_conditional_overwrite_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s274_dependent_conditional_overwrite.c`](../../../c/t/tsvc_s274_dependent_conditional_overwrite.c) |
| C3 | [`tsvc_s274_dependent_conditional_overwrite.c3`](../../../c3/t/tsvc_s274_dependent_conditional_overwrite.c3) |
| C++ | [`tsvc_s274_dependent_conditional_overwrite.cpp`](../../../cpp/t/tsvc_s274_dependent_conditional_overwrite.cpp) |
| Elisa | [`tsvc_s274_dependent_conditional_overwrite.elisa`](../../../elisa/t/tsvc_s274_dependent_conditional_overwrite.elisa) |
| Nim | [`tsvc_s274_dependent_conditional_overwrite.nim`](../../../nim/t/tsvc_s274_dependent_conditional_overwrite.nim) |
| Odin | [`tsvc_s274_dependent_conditional_overwrite.odin`](../../../odin/t/tsvc_s274_dependent_conditional_overwrite.odin) |
| Rust | [`tsvc_s274_dependent_conditional_overwrite.rs`](../../../rust/t/tsvc_s274_dependent_conditional_overwrite.rs) |
| V | [`tsvc_s274_dependent_conditional_overwrite.v`](../../../v/t/tsvc_s274_dependent_conditional_overwrite.v) |
| Zig | [`tsvc_s274_dependent_conditional_overwrite.zig`](../../../zig/t/tsvc_s274_dependent_conditional_overwrite.zig) |
