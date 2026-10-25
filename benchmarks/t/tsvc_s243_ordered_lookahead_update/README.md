# TSVC s243 ordered lookahead update

This package is a bounded, clean-room, one-sweep profile of TSVC `s243` from
the `NodeSplitting-dbl` family. For every index except the final one, it runs
three ordered updates:

```text
A[i] = B[i] + C[i] * D[i]
B[i] = A[i] + D[i] * E[i]
A[i] = B[i] + A[i+1] * D[i]
```

The second statement reads the newly assigned A[i]. The third uses the newly
assigned B[i] and the still-old A[i+1], then overwrites A[i]. The final A and
B slots remain unchanged. This differs from `s241`'s coupled product-only map
and from `s323`'s previous-B coupled recurrence. It also differs from
`s212`, whose A update occurs once and whose B update accumulates a scaled
lookahead value.

## Contract

The exported symbol is `tsvc_s243_ordered_lookahead_update`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, A[n], B[n], C[n], D[n], E[n]]`, with `n` in `2..64`.
- Every input value is in `[-2,2]`. Outputs remain small integers exactly
  representable by the source's binary64 `TYPE` profile.
- Perform one ascending sweep over indices `0..n-2`, preserving statement
  order. Leave A[n-1] and B[n-1] unchanged.
- Emit final A followed by final B as little-endian signed i64 values and
  return `2*n`. Required output capacity is `16*n` bytes.
- Malformed input returns `-1`; null output or insufficient capacity returns
  `-2` without writes. Input is unchanged.

The upstream benchmark repeats the loop for timing, and repeated passes can
change the arrays. This bounded package profiles one loop-body pass with
explicit input and final arrays instead of that timing trajectory. The source
initializes A to zero, B to one, and C/D/E to reciprocal values; the workload
varies bounded integers to expose the ordered update and lookahead.

## Source and rights

The behavior reference is `s243` at lines 2209–2233 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2209),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its initialization is at lines
420–425. The launcher is
[`TSVC/NodeSplitting-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/NodeSplitting-dbl/tsc.c),
which selects `TYPE double` and the node-splitting family. TSVC comments
attribute its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s243_ordered_lookahead_update_oracle.py`](../../tsvc_s243_ordered_lookahead_update_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s243_ordered_lookahead_update.c`](../../../c/t/tsvc_s243_ordered_lookahead_update.c) |
| C3 | [`tsvc_s243_ordered_lookahead_update.c3`](../../../c3/t/tsvc_s243_ordered_lookahead_update.c3) |
| C++ | [`tsvc_s243_ordered_lookahead_update.cpp`](../../../cpp/t/tsvc_s243_ordered_lookahead_update.cpp) |
| Elisa | [`tsvc_s243_ordered_lookahead_update.elisa`](../../../elisa/t/tsvc_s243_ordered_lookahead_update.elisa) |
| Nim | [`tsvc_s243_ordered_lookahead_update.nim`](../../../nim/t/tsvc_s243_ordered_lookahead_update.nim) |
| Odin | [`tsvc_s243_ordered_lookahead_update.odin`](../../../odin/t/tsvc_s243_ordered_lookahead_update.odin) |
| Rust | [`tsvc_s243_ordered_lookahead_update.rs`](../../../rust/t/tsvc_s243_ordered_lookahead_update.rs) |
| V | [`tsvc_s243_ordered_lookahead_update.v`](../../../v/t/tsvc_s243_ordered_lookahead_update.v) |
| Zig | [`tsvc_s243_ordered_lookahead_update.zig`](../../../zig/t/tsvc_s243_ordered_lookahead_update.zig) |
