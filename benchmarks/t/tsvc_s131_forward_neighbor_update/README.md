# TSVC s131 forward-neighbor update

This package implements a bounded clean-room profile of TSVC `s131`, the
global-data-flow forward-substitution loop. Each pass visits `i` upward and
assigns `a[i] = a[i+1] + b[i]` for all but the final element. Because the loop
moves left to right, each read of `a[i+1]` observes that element before it has
been updated in the current pass. The final element remains unchanged.

This is a one-dimensional right-neighbor recurrence. It is distinct from
TSVC `s281`, whose loop reads a reverse-indexed element, and from dense
triangular-system solvers such as `trisolv` and `polybench_ludcmp`. TSVC `s151`
uses the same operation through a helper call with offset one and is treated
as a duplicate rather than a separate package.

## Contract

The exported symbol is `tsvc_s131_forward_neighbor_update` and uses the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, a[n], b[n]]`; `n` is in `1..64` and `passes` in
  `1..32`.
- Every initial array element is in `[-1,000,000,1,000,000]`. The bounded
  recurrence stays within signed i64.
- Each pass visits `i` in increasing order from zero through `n-2`, applying
  `a[i] = a[i+1] + b[i]`. `a[n-1]` is unchanged.
- Input is unchanged. On success, the final `a` vector is emitted as
  little-endian signed i64 values and the function returns `n`.
- Malformed input returns `-1`. Null output or capacity below `8*n` returns
  `-2`; validation happens first and errors write no output.

`passes` is a bounded explicit replacement for the source benchmark's large
timing loop; it preserves the kernel's per-pass iteration order and array
update behavior.

## Source and rights

The behavior reference is `s131` in the pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1423)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`; the `GlobalDataFlow-dbl` launcher
selects the double-precision codelet. Its source initialization sets `a` to
one and `b[i]` to `1/(i+1)^2`; the package accepts bounded caller-provided
integer arrays to make the loop behavior directly testable. The TSVC source
attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*. No explicit license
grant was found in the pinned source or repository material reviewed. These
ports independently implement the bounded mathematical loop, reuse no
upstream source or comments, and claim no upstream license or endorsement.
See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and cases are
[`tsvc_s131_forward_neighbor_update_oracle.py`](../../tsvc_s131_forward_neighbor_update_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s131_forward_neighbor_update.c`](../../../c/t/tsvc_s131_forward_neighbor_update.c) |
| C3 | [`tsvc_s131_forward_neighbor_update.c3`](../../../c3/t/tsvc_s131_forward_neighbor_update.c3) |
| C++ | [`tsvc_s131_forward_neighbor_update.cpp`](../../../cpp/t/tsvc_s131_forward_neighbor_update.cpp) |
| Elisa | [`tsvc_s131_forward_neighbor_update.elisa`](../../../elisa/t/tsvc_s131_forward_neighbor_update.elisa) |
| Nim | [`tsvc_s131_forward_neighbor_update.nim`](../../../nim/t/tsvc_s131_forward_neighbor_update.nim) |
| Odin | [`tsvc_s131_forward_neighbor_update.odin`](../../../odin/t/tsvc_s131_forward_neighbor_update.odin) |
| Rust | [`tsvc_s131_forward_neighbor_update.rs`](../../../rust/t/tsvc_s131_forward_neighbor_update.rs) |
| V | [`tsvc_s131_forward_neighbor_update.v`](../../../v/t/tsvc_s131_forward_neighbor_update.v) |
| Zig | [`tsvc_s131_forward_neighbor_update.zig`](../../../zig/t/tsvc_s131_forward_neighbor_update.zig) |
