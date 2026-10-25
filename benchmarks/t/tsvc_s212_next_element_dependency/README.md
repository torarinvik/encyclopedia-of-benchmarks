# TSVC s212 next-element dependency

This package is a bounded clean-room implementation of TSVC `s212` from the
`StatementReordering-dbl` family. Each pass visits `i=0..n-2` in ascending
order and performs these statements in sequence:

1. `a[i] *= c[i]`
2. `b[i] += a[i+1] * d[i]`

At each step, `a[i+1]` has not yet been updated in the current pass. The last
element of A and B is unchanged by a pass. Repeating passes makes the updated
A values from previous passes visible to the next pass.

This is distinct from s211's two-sided B neighbor rewrite: s212 scales A at
the current index and accumulates the still-unmodified next A value into B.
Both kernels reside in TSVC's statement-reordering launcher family, but their
dataflow contracts differ.

## Contract

The exported symbol is `tsvc_s212_next_element_dependency`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, passes, a[n], b[n], c[n], d[n]]`, with `n` in `2..64` and
  `passes` in `1..16`.
- Every array value is in `[-2,2]`. The bounded multiplication and
  accumulation stay exact in the source's binary64 type and fit signed i64.
- Each pass visits indices in ascending order from zero through `n-2`; apply
  the A multiplication, then the B accumulation at every index.
- Input is unchanged. On success, output is final A followed by final B,
  encoded as little-endian signed i64 values. The function returns `2*n`.
- Malformed input returns `-1`. Null output or capacity below `16*n` returns
  `-2`; validation happens first and errors write no output.

## Source and rights

The behavior reference is `s212` in the pinned
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc)
(the codelet starts at [line 1859](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1859))
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/StatementReordering-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/StatementReordering-dbl/tsc.c),
which selects `TYPE double` and the statement-reordering codelets. Source
initialization sets B and C to one, and A/D to reciprocal-index values; this
profile instead accepts bounded caller arrays to make the dependency
observable. The TSVC source attributes its non-four-digit codelets to David
Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*. No explicit license grant was found in the pinned source or
repository material reviewed. These ports independently implement the
bounded mathematical loop, reuse no upstream source or comments, and claim no
upstream license or endorsement. See [`LICENSE.txt`](LICENSE.txt) for the
rights note.

The oracle and cases are
[`tsvc_s212_next_element_dependency_oracle.py`](../../tsvc_s212_next_element_dependency_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s212_next_element_dependency.c`](../../../c/t/tsvc_s212_next_element_dependency.c) |
| C3 | [`tsvc_s212_next_element_dependency.c3`](../../../c3/t/tsvc_s212_next_element_dependency.c3) |
| C++ | [`tsvc_s212_next_element_dependency.cpp`](../../../cpp/t/tsvc_s212_next_element_dependency.cpp) |
| Elisa | [`tsvc_s212_next_element_dependency.elisa`](../../../elisa/t/tsvc_s212_next_element_dependency.elisa) |
| Nim | [`tsvc_s212_next_element_dependency.nim`](../../../nim/t/tsvc_s212_next_element_dependency.nim) |
| Odin | [`tsvc_s212_next_element_dependency.odin`](../../../odin/t/tsvc_s212_next_element_dependency.odin) |
| Rust | [`tsvc_s212_next_element_dependency.rs`](../../../rust/t/tsvc_s212_next_element_dependency.rs) |
| V | [`tsvc_s212_next_element_dependency.v`](../../../v/t/tsvc_s212_next_element_dependency.v) |
| Zig | [`tsvc_s212_next_element_dependency.zig`](../../../zig/t/tsvc_s212_next_element_dependency.zig) |
