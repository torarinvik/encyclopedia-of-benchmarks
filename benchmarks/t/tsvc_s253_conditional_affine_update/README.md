# TSVC s253 conditional affine update

This package is a bounded clean-room profile of TSVC `s253` in the
`Expansion-dbl` family. For each ascending array position, the kernel checks
whether A is greater than B. If so, it computes one temporary, adds it to C,
and stores it back to A:

```text
if A[i] > B[i]:
    value = A[i] - B[i] * D[i]
    C[i] += value
    A[i] = value
```

The condition is evaluated against the current A value at the beginning of
each pass. B and D remain unchanged; updated A and C values carry into the
next pass.

## Contract

The exported symbol is `tsvc_s253_conditional_affine_update`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, A[n], B[n], C[n], D[n]]`, with `n` in 1 through 64 and
  `passes` in 1 through 8.
- All A, B, C, and D inputs are in `[-2,2]`.
- For each pass and ascending i, if `A[i] > B[i]`, compute
  `value=A[i]-B[i]*D[i]`, then update `C[i]+=value` and `A[i]=value`.
- On success, output final A followed by final C as little-endian signed i64
  values and return `2*n`.
- Malformed input returns `-1`; null output or capacity below `16*n` bytes
  returns `-2` without writing output.

With at most eight passes, all updates stay within small signed integers and
are exact in the source's binary64 `TYPE`. The profile performs a bounded
number of full sweeps and leaves the caller input unchanged; the source's
launcher repetitions, timing, dummy calls, and checker are omitted.

This is distinct from s273's update-A-then-test-negative dependent branch and
s278's sign-controlled B/C assignment followed by common A recomputation.
It is also distinct from s124's branch-selected value map, which does not
mutate persistent A/C state.

## Source and rights

The behavior reference is `s253` in `TSVC/tsc.inc`, lines 2453–2480, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2453). The
[`Expansion-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/tsc.c)
selects double precision; its `info.sh` run options are `4160 14`. TSVC
comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit upstream license grant was found in the pinned source or
repository material reviewed. These ports independently implement the bounded
operation and reuse no upstream code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s253_conditional_affine_update_oracle.py`](../../tsvc_s253_conditional_affine_update_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s253_conditional_affine_update.c`](../../../c/t/tsvc_s253_conditional_affine_update.c) |
| C3 | [`tsvc_s253_conditional_affine_update.c3`](../../../c3/t/tsvc_s253_conditional_affine_update.c3) |
| C++ | [`tsvc_s253_conditional_affine_update.cpp`](../../../cpp/t/tsvc_s253_conditional_affine_update.cpp) |
| Elisa | [`tsvc_s253_conditional_affine_update.elisa`](../../../elisa/t/tsvc_s253_conditional_affine_update.elisa) |
| Nim | [`tsvc_s253_conditional_affine_update.nim`](../../../nim/t/tsvc_s253_conditional_affine_update.nim) |
| Odin | [`tsvc_s253_conditional_affine_update.odin`](../../../odin/t/tsvc_s253_conditional_affine_update.odin) |
| Rust | [`tsvc_s253_conditional_affine_update.rs`](../../../rust/t/tsvc_s253_conditional_affine_update.rs) |
| V | [`tsvc_s253_conditional_affine_update.v`](../../../v/t/tsvc_s253_conditional_affine_update.v) |
| Zig | [`tsvc_s253_conditional_affine_update.zig`](../../../zig/t/tsvc_s253_conditional_affine_update.zig) |
