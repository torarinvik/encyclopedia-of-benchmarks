# TSVC indexed gather and scatter updates

This bounded package contains two distinct indirect-addressing codelet
contracts from TSVC: `s491` and `s4113`. Both scatter writes through an index
array and preserve source-order behavior when indices repeat. `s491` is
scatter-only on its right-hand operands: `a[ip[i]] = b[i] + c[i] * d[i]`.
`s4113` gathers `b` through the same index before scattering: `a[ip[i]] =
b[ip[i]] + c[i]`. The package exposes them as separate mode values, 491 and
4113, because their right-hand access patterns are different contracts.

## Contract

The exported function is `tsvc_indexed_gather_scatter` and uses the
`i64_array_bytes_output` ABI:

- Input starts with `[codelet, n]`, where `codelet` is 491 or 4113 and
  `n` is in `1..16`.
- Then come `index[n]`, `destination[n]`, `b[n]`, and `c[n]`; mode 491 also
  carries `d[n]`. Thus mode 491 has exactly `2 + 5*n` inputs and mode 4113 has
  exactly `2 + 4*n`.
- Every index is in `0..n-1`. Repeated indices are allowed and each loop
  iteration writes immediately, so the last write to an index wins.
- `b`, `c`, and (for mode 491) `d` values are in `[-1,000,000,1,000,000]`.
  The initial destination values may be any signed i64. These bounds keep both
  source expressions within signed i64 range.
- Mode 491 visits `i` upward and assigns
  `destination[index[i]] = b[i] + c[i] * d[i]`.
- Mode 4113 visits `i` upward and assigns
  `destination[index[i]] = b[index[i]] + c[i]`.
- Input is unchanged. On success, the final `destination[n]` is emitted as
  little-endian signed i64 values and the function returns `n`.
- Malformed input returns `-1`. A null output pointer or output capacity below
  `8*n` returns `-2`. Validation errors take precedence and errors write no
  output.

This is an indexed vector update family, not a permutation generator, matrix
compaction, sparse dot product, or queue operation. It preserves duplicate
index collision behavior rather than requiring a permutation.

## Source and rights

The clean-room behavior reference is `s491` and `s4113` in the pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4678)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source comments identify
`s491` as indirect scatter and `s4113` as gather plus scatter. The TSVC source
attributes its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*. No explicit license
grant was found in the pinned TSVC source or repository material reviewed.
This package independently implements the bounded loop behavior and reuses
no upstream source code or comments; no upstream license or endorsement is
claimed. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and cases are
[`tsvc_indexed_gather_scatter_oracle.py`](../../tsvc_indexed_gather_scatter_oracle.py)
and [`workload.json`](workload.json). The workload exercises both contracts,
repeated destinations, untouched entries, and invalid frames.

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_indexed_gather_scatter.c`](../../../c/t/tsvc_indexed_gather_scatter.c) |
| C3 | [`tsvc_indexed_gather_scatter.c3`](../../../c3/t/tsvc_indexed_gather_scatter.c3) |
| C++ | [`tsvc_indexed_gather_scatter.cpp`](../../../cpp/t/tsvc_indexed_gather_scatter.cpp) |
| Elisa | [`tsvc_indexed_gather_scatter.elisa`](../../../elisa/t/tsvc_indexed_gather_scatter.elisa) |
| Nim | [`tsvc_indexed_gather_scatter.nim`](../../../nim/t/tsvc_indexed_gather_scatter.nim) |
| Odin | [`tsvc_indexed_gather_scatter.odin`](../../../odin/t/tsvc_indexed_gather_scatter.odin) |
| Rust | [`tsvc_indexed_gather_scatter.rs`](../../../rust/t/tsvc_indexed_gather_scatter.rs) |
| V | [`tsvc_indexed_gather_scatter.v`](../../../v/t/tsvc_indexed_gather_scatter.v) |
| Zig | [`tsvc_indexed_gather_scatter.zig`](../../../zig/t/tsvc_indexed_gather_scatter.zig) |
