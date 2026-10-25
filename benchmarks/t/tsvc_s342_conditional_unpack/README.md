# TSVC s342 conditional unpack

This package implements a bounded, clean-room, one-sweep profile of TSVC
`s342` from the `Packing-dbl` family. It walks destination array A in order.
When the current A value is positive, it replaces that slot with the next
value from the packed prefix of B:

```text
packed_index = 0
for i from 0 to n-1:
    if A[i] > 0:
        A[i] = B[packed_index]
        packed_index += 1
```

This is a conditional unpack/expand operation: the positive values in A mark
destination positions, and B supplies values sequentially. It differs from
[`tsvc_vif_masked_assignment`](../tsvc_vif_masked_assignment/README.md),
which copies B at the same index when B is positive; from
[`tsvc_s343_column_major_compaction`](../tsvc_s343_column_major_compaction/README.md),
which packs a two-dimensional payload into a shorter vector; and from
[`tsvc_indexed_gather_scatter`](../tsvc_indexed_gather_scatter/README.md),
which uses explicit indices rather than a positive mask.

## Contract

The exported symbol is `tsvc_s342_conditional_unpack`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, A[n], B[n]]`, with `n` in `1..64` and all values in `[-2,2]`.
- In one ascending sweep, consume `B[0]`, `B[1]`, … only at positions whose
  original A value is positive. Copy each consumed value into that A slot;
  retain other A values. Unconsumed suffix values in B do not affect output.
- Return the final A vector as little-endian signed i64 values and return `n`.
- Malformed input returns `-1`. Null output or capacity below `8*n` returns
  `-2` without writes. Input is unchanged.

The source benchmark repeats this in-place loop for timing, so later passes
may use values written by earlier passes as the mask. This package profiles
one execution of the loop body to expose the operation with explicit input
and output; it does not claim to model repeated-pass state evolution. The
source initializes A and B with positive reciprocal values, making all
destinations active on its default pass. The bounded caller workload varies A
to exercise both selected and retained positions.

## Source and rights

The behavior reference is `s342` at lines 4004–4032 in
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4004),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The source initialization for
`s342` is at line 616. Its launcher is
[`TSVC/Packing-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Packing-dbl/tsc.c),
which selects `TYPE double` and packing codelets. TSVC comments attribute the
non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s342_conditional_unpack_oracle.py`](../../tsvc_s342_conditional_unpack_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s342_conditional_unpack.c`](../../../c/t/tsvc_s342_conditional_unpack.c) |
| C3 | [`tsvc_s342_conditional_unpack.c3`](../../../c3/t/tsvc_s342_conditional_unpack.c3) |
| C++ | [`tsvc_s342_conditional_unpack.cpp`](../../../cpp/t/tsvc_s342_conditional_unpack.cpp) |
| Elisa | [`tsvc_s342_conditional_unpack.elisa`](../../../elisa/t/tsvc_s342_conditional_unpack.elisa) |
| Nim | [`tsvc_s342_conditional_unpack.nim`](../../../nim/t/tsvc_s342_conditional_unpack.nim) |
| Odin | [`tsvc_s342_conditional_unpack.odin`](../../../odin/t/tsvc_s342_conditional_unpack.odin) |
| Rust | [`tsvc_s342_conditional_unpack.rs`](../../../rust/t/tsvc_s342_conditional_unpack.rs) |
| V | [`tsvc_s342_conditional_unpack.v`](../../../v/t/tsvc_s342_conditional_unpack.v) |
| Zig | [`tsvc_s342_conditional_unpack.zig`](../../../zig/t/tsvc_s342_conditional_unpack.zig) |
