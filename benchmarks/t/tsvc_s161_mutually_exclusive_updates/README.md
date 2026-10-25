# TSVC s161 mutually exclusive updates

This package is a bounded clean-room implementation of TSVC `s161` from the
`ControlFlow-dbl` family. In an ascending sweep over `i=0..n-2`, the condition
on `b[i]` selects exactly one update:

- If `b[i] < 0`, assign `c[i+1] = a[i] + d[i]*d[i]`.
- Otherwise, assign `a[i] = c[i] + d[i]*e[i]`.

The ascending order matters. A negative branch can write `c[i+1]`, and the
next iteration's nonnegative branch can immediately read that updated value
to write `a[i+1]`. The package returns both changed arrays so this dependency
is observable.

This differs from TSVC `s273`, which updates A first and tests the updated A
to conditionally update B and then C at the same index. It also differs from
`s1161`, which branches on C and updates B at index `i` on its negative path.
The source repeats the sweep in its timing loop; with B fixed, one sweep is
already a fixed point for these mutually exclusive assignments, so the
package profiles one source-shaped sweep.

## Contract

The exported symbol is `tsvc_s161_mutually_exclusive_updates`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, a[n], b[n], c[n], d[n], e[n]]`, with `n` in `2..64`.
- All entries are in `[-2,2]`; all arithmetic remains exact in the source's
  double-precision type and fits signed i64.
- Visit `i` from zero upward through `n-2`, applying exactly the branch
  selected by the original `b[i] < 0` condition.
- Input is unchanged. On success, concatenate final A and C and emit the
  `2*n` signed i64 values in little-endian order. The function returns `2*n`.
- Malformed input returns `-1`. Null output or capacity below `16*n` returns
  `-2`; validation happens first and errors write no output.

## Source and rights

The behavior reference is `s161` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1570)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`TSVC/ControlFlow-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c),
which selects `TYPE double` and control-flow codelets. The source initializes
A and C to one, B with alternating positive and negative values, and D/E to
reciprocal-index values; this bounded package accepts caller-provided values
to expose both branches and their inter-iteration effect. The TSVC source
attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*. No explicit license
grant was found in the pinned source or repository material reviewed. These
ports independently implement the bounded mathematical behavior, reuse no
upstream source or comments, and claim no upstream license or endorsement.
See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and cases are
[`tsvc_s161_mutually_exclusive_updates_oracle.py`](../../tsvc_s161_mutually_exclusive_updates_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s161_mutually_exclusive_updates.c`](../../../c/t/tsvc_s161_mutually_exclusive_updates.c) |
| C3 | [`tsvc_s161_mutually_exclusive_updates.c3`](../../../c3/t/tsvc_s161_mutually_exclusive_updates.c3) |
| C++ | [`tsvc_s161_mutually_exclusive_updates.cpp`](../../../cpp/t/tsvc_s161_mutually_exclusive_updates.cpp) |
| Elisa | [`tsvc_s161_mutually_exclusive_updates.elisa`](../../../elisa/t/tsvc_s161_mutually_exclusive_updates.elisa) |
| Nim | [`tsvc_s161_mutually_exclusive_updates.nim`](../../../nim/t/tsvc_s161_mutually_exclusive_updates.nim) |
| Odin | [`tsvc_s161_mutually_exclusive_updates.odin`](../../../odin/t/tsvc_s161_mutually_exclusive_updates.odin) |
| Rust | [`tsvc_s161_mutually_exclusive_updates.rs`](../../../rust/t/tsvc_s161_mutually_exclusive_updates.rs) |
| V | [`tsvc_s161_mutually_exclusive_updates.v`](../../../v/t/tsvc_s161_mutually_exclusive_updates.v) |
| Zig | [`tsvc_s161_mutually_exclusive_updates.zig`](../../../zig/t/tsvc_s161_mutually_exclusive_updates.zig) |
