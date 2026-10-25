# TSVC s452 index-weighted vector map

This package is a bounded clean-room implementation of TSVC `s452` from the
`GlobalDataFlow-dbl` family. It computes one output element per input index:

```text
a[i] = b[i] + c[i] * (i + 1)
```

The source repeats this full assignment in its timing loop, but B and C remain
unchanged, so the output reaches its final state after one sweep. The package
returns that complete A vector.

This is not the same as TSVC s131's forward-neighbor recurrence, s132's
shifted-row update, s141's packed symmetric update, or s152's three-factor
accumulation. It also differs from s431's in-place A/B addition: s452 scales
each C entry by its one-based position before adding B.

## Contract

The exported symbol is `tsvc_s452_index_weighted_vector_map`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, b[n], c[n]]`, with `n` in `1..64`.
- Every B and C value is in `[-2,2]`. The largest result has magnitude at
  most 130, so the bounded integer profile is exact in the source binary64
  type and fits signed i64.
- For each ascending index `i`, compute `b[i] + c[i]*(i+1)`.
- Input is unchanged. On success, output A as little-endian signed i64 values
  and return `n`; output capacity must be at least `8*n` bytes.
- Malformed input returns `-1`. Null output or insufficient capacity returns
  `-2`; validation happens first and errors write no output.

## Source and rights

The behavior reference is `s452` in pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4523)
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/GlobalDataFlow-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/GlobalDataFlow-dbl/tsc.c),
which selects `TYPE double` and global-data-flow codelets. Source
initialization sets B to one and C to a small constant; this bounded profile
accepts caller arrays so the positional weighting is observable. The TSVC
source attributes its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*. No
explicit license grant was found in the pinned source or repository material
reviewed. These ports independently implement the bounded mathematical
loop, reuse no upstream source or comments, and claim no upstream license or
endorsement. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The oracle and cases are
[`tsvc_s452_index_weighted_vector_map_oracle.py`](../../tsvc_s452_index_weighted_vector_map_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s452_index_weighted_vector_map.c`](../../../c/t/tsvc_s452_index_weighted_vector_map.c) |
| C3 | [`tsvc_s452_index_weighted_vector_map.c3`](../../../c3/t/tsvc_s452_index_weighted_vector_map.c3) |
| C++ | [`tsvc_s452_index_weighted_vector_map.cpp`](../../../cpp/t/tsvc_s452_index_weighted_vector_map.cpp) |
| Elisa | [`tsvc_s452_index_weighted_vector_map.elisa`](../../../elisa/t/tsvc_s452_index_weighted_vector_map.elisa) |
| Nim | [`tsvc_s452_index_weighted_vector_map.nim`](../../../nim/t/tsvc_s452_index_weighted_vector_map.nim) |
| Odin | [`tsvc_s452_index_weighted_vector_map.odin`](../../../odin/t/tsvc_s452_index_weighted_vector_map.odin) |
| Rust | [`tsvc_s452_index_weighted_vector_map.rs`](../../../rust/t/tsvc_s452_index_weighted_vector_map.rs) |
| V | [`tsvc_s452_index_weighted_vector_map.v`](../../../v/t/tsvc_s452_index_weighted_vector_map.v) |
| Zig | [`tsvc_s452_index_weighted_vector_map.zig`](../../../zig/t/tsvc_s452_index_weighted_vector_map.zig) |
