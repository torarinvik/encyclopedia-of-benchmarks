# TSVC s278 branch recomputation

This package is a bounded clean-room implementation of TSVC `s278` from the
`ControlFlow-dbl` family. Each ascending element visit chooses one update
based on the current A value, then recomputes A using the resulting B and C:

- If `a[i] > 0`, assign `c[i] = -c[i] + d[i]*e[i]`.
- Otherwise, assign `b[i] = -b[i] + d[i]*e[i]`.
- In both cases, assign `a[i] = b[i] + c[i]*d[i]`.

The input branch is evaluated before either B or C changes. Across repeated
passes, A from the previous pass determines which state variable is updated;
the final output includes all three arrays to expose both the branch and the
common recomputation.

This differs from TSVC s161, which branches on B and writes A or the next C
element, and from s273, which uses a threshold condition to select dependent
updates to B and C after changing A. In s278, each index updates one of B/C
based on the prior A and then always rebuilds A from B and C.

## Contract

The exported symbol is `tsvc_s278_branch_recompute`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, a[n], b[n], c[n], d[n], e[n]]`, with `n` in `1..64`
  and `passes` in `1..16`.
- Every initial array element is in `[-2,2]`. The bounded recurrence remains
  exact in the source's binary64 type and fits signed i64.
- Each pass visits indices upward from zero through `n-1`. Apply the selected
  B or C update, then recompute A at the same index.
- Input is unchanged. Output is final A followed by final B followed by final
  C, encoded as little-endian signed i64 values. The function returns `3*n`.
- Malformed input returns `-1`. Null output or capacity below `24*n` returns
  `-2`; validation happens first and errors write no output.

## Source and rights

The behavior reference is `s278` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2894)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/ControlFlow-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c),
which selects `TYPE double` and control-flow codelets. Source initialization
sets A's first half to -1 and second half to +1, B to one, and C/D/E to
reciprocal-index values; this profile accepts bounded caller arrays so both
branch paths and repeated state changes are observable. The TSVC source
attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*. No explicit license
grant was found in the pinned source or repository material reviewed. These
ports independently implement the bounded mathematical loop, reuse no
upstream source or comments, and claim no upstream license or endorsement.
See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and cases are
[`tsvc_s278_branch_recompute_oracle.py`](../../tsvc_s278_branch_recompute_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s278_branch_recompute.c`](../../../c/t/tsvc_s278_branch_recompute.c) |
| C3 | [`tsvc_s278_branch_recompute.c3`](../../../c3/t/tsvc_s278_branch_recompute.c3) |
| C++ | [`tsvc_s278_branch_recompute.cpp`](../../../cpp/t/tsvc_s278_branch_recompute.cpp) |
| Elisa | [`tsvc_s278_branch_recompute.elisa`](../../../elisa/t/tsvc_s278_branch_recompute.elisa) |
| Nim | [`tsvc_s278_branch_recompute.nim`](../../../nim/t/tsvc_s278_branch_recompute.nim) |
| Odin | [`tsvc_s278_branch_recompute.odin`](../../../odin/t/tsvc_s278_branch_recompute.odin) |
| Rust | [`tsvc_s278_branch_recompute.rs`](../../../rust/t/tsvc_s278_branch_recompute.rs) |
| V | [`tsvc_s278_branch_recompute.v`](../../../v/t/tsvc_s278_branch_recompute.v) |
| Zig | [`tsvc_s278_branch_recompute.zig`](../../../zig/t/tsvc_s278_branch_recompute.zig) |
