# TSVC s141 packed symmetric update

This package is a bounded clean-room implementation of TSVC `s141`, which
accumulates the lower triangle of a dense matrix into packed symmetric storage.
For each `i` from zero through `n-1`, it visits `j` from `i` through `n-1` and
updates `packed[j*(j+1)/2+i] += matrix[j*n+i]`. The packed order is grouped by
column `j`, including its diagonal, with `i <= j`.

This is distinct from dense symmetric matrix multiplication such as
`polybench_symm` and from triangular matrix multiplication: it performs no
products and uses a triangular packed destination. It also differs from the
TSVC indexed gather/scatter package, which writes arbitrary caller-supplied
indices rather than traversing a symmetric triangle.

## Contract

The exported symbol is `tsvc_s141_packed_symmetric_update`, using the
`i64_array_bytes_output` ABI.

- Input is `[n, rounds, packed[t], matrix[n*n]]`, where
  `t = n*(n+1)/2`, `n` is in `1..16`, and `rounds` is in `1..32`.
- Both packed initial values and dense matrix entries are in
  `[-1,000,000,1,000,000]`. All updates therefore fit signed i64.
- The dense matrix is row-major. The source subscript `bb[j][i]` maps to
  `matrix[j*n+i]`; entries above its diagonal are validated but unused.
- Each round visits `i` upward, then `j` upward from `i` to `n-1`. The packed
  destination index is `j*(j+1)/2+i`.
- Input is unchanged. On success, the final packed vector is emitted as
  little-endian signed i64 values and the function returns `t`.
- Malformed input returns `-1`. Null output or insufficient capacity returns
  `-2`; validation happens first and errors write no output.

`rounds` makes the repeated accumulation count explicit and bounded. It
represents a small deterministic profile of the source's repeated loop, not
the upstream benchmark timing harness or its global initialization.

## Source and rights

The behavior reference is `s141` in the pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1476)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its comments describe walking a
row in a symmetric packed array and give the one-based packed-location rule.
The TSVC source attributes its non-four-digit codelets to David Callahan,
Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No
explicit license grant was found in the pinned source or repository material
reviewed. These ports independently implement only the bounded mathematical
loop contract; no upstream code or comments are reused, and no upstream
license or endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt) for the
rights note.

The independent reference model and workload are
[`tsvc_s141_packed_symmetric_update_oracle.py`](../../tsvc_s141_packed_symmetric_update_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s141_packed_symmetric_update.c`](../../../c/t/tsvc_s141_packed_symmetric_update.c) |
| C3 | [`tsvc_s141_packed_symmetric_update.c3`](../../../c3/t/tsvc_s141_packed_symmetric_update.c3) |
| C++ | [`tsvc_s141_packed_symmetric_update.cpp`](../../../cpp/t/tsvc_s141_packed_symmetric_update.cpp) |
| Elisa | [`tsvc_s141_packed_symmetric_update.elisa`](../../../elisa/t/tsvc_s141_packed_symmetric_update.elisa) |
| Nim | [`tsvc_s141_packed_symmetric_update.nim`](../../../nim/t/tsvc_s141_packed_symmetric_update.nim) |
| Odin | [`tsvc_s141_packed_symmetric_update.odin`](../../../odin/t/tsvc_s141_packed_symmetric_update.odin) |
| Rust | [`tsvc_s141_packed_symmetric_update.rs`](../../../rust/t/tsvc_s141_packed_symmetric_update.rs) |
| V | [`tsvc_s141_packed_symmetric_update.v`](../../../v/t/tsvc_s141_packed_symmetric_update.v) |
| Zig | [`tsvc_s141_packed_symmetric_update.zig`](../../../zig/t/tsvc_s141_packed_symmetric_update.zig) |
