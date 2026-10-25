# TSVC s272 thresholded dual accumulate

This package is a bounded clean-room profile of TSVC `s272` from the
`ControlFlow-dbl` family. For every ascending index whose E value meets a
caller-supplied threshold, the loop updates A and B in place:

```text
if E[i] >= threshold:
    A[i] += C[i] * D[i]
    B[i] += C[i] * C[i]
```

Both updates run on the same branch. The condition depends only on E and the
threshold, so each position's branch remains fixed across passes. C, D, and E
are unchanged.

## Contract

The exported symbol is `tsvc_s272_threshold_dual_accumulate`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, threshold, A[n], B[n], C[n], D[n], E[n]]`, with `n`
  in 1 through 64 and `passes` in 1 through 8.
- The threshold and all array values are in `[-2,2]`.
- For each pass and ascending i, when `E[i] >= threshold`, update
  `A[i] += C[i]*D[i]` then `B[i] += C[i]*C[i]`.
- On success, output final A followed by final B as little-endian signed i64
  values and return `2*n`.
- Malformed input returns `-1`; null output or capacity below `16*n` bytes
  returns `-2` without writing output.

At most eight passes keep both arrays within `[-34,34]`; products and sums are
exact integers in the source's binary64 `TYPE` and fit signed i64. The pinned
launcher passes threshold `s1=1.0`; the bounded input exposes equality and
other threshold positions as cases. Timing, dummy calls, and checker code are
outside this package.

This operation differs from s273's dependent negative test after updating A,
and from s274's branch on newly computed A that either updates B or overwrites
A. s272 branches on unchanged E and always updates both A and B when selected.

## Source and rights

The behavior reference is `s272` in `TSVC/tsc.inc`, lines 2687–2712, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2687). The
[`ControlFlow-dbl` launcher](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c)
selects double precision and calls `s272(s1)`; `set()` initializes `s1` to
1.0. The launcher options in `info.sh` are `2325 14`. TSVC comments attribute
its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit upstream license grant was found in the pinned source or
repository material reviewed. These ports independently implement the bounded
operation and reuse no upstream code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s272_threshold_dual_accumulate_oracle.py`](../../tsvc_s272_threshold_dual_accumulate_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s272_threshold_dual_accumulate.c`](../../../c/t/tsvc_s272_threshold_dual_accumulate.c) |
| C3 | [`tsvc_s272_threshold_dual_accumulate.c3`](../../../c3/t/tsvc_s272_threshold_dual_accumulate.c3) |
| C++ | [`tsvc_s272_threshold_dual_accumulate.cpp`](../../../cpp/t/tsvc_s272_threshold_dual_accumulate.cpp) |
| Elisa | [`tsvc_s272_threshold_dual_accumulate.elisa`](../../../elisa/t/tsvc_s272_threshold_dual_accumulate.elisa) |
| Nim | [`tsvc_s272_threshold_dual_accumulate.nim`](../../../nim/t/tsvc_s272_threshold_dual_accumulate.nim) |
| Odin | [`tsvc_s272_threshold_dual_accumulate.odin`](../../../odin/t/tsvc_s272_threshold_dual_accumulate.odin) |
| Rust | [`tsvc_s272_threshold_dual_accumulate.rs`](../../../rust/t/tsvc_s272_threshold_dual_accumulate.rs) |
| V | [`tsvc_s272_threshold_dual_accumulate.v`](../../../v/t/tsvc_s272_threshold_dual_accumulate.v) |
| Zig | [`tsvc_s272_threshold_dual_accumulate.zig`](../../../zig/t/tsvc_s272_threshold_dual_accumulate.zig) |
