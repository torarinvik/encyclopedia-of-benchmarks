# TSVC vag indexed gather copy

This package is a bounded, clean-room profile of TSVC `vag` from the
`ControlLoops-dbl` launcher family. It writes a sequential output vector from
an index vector:

```text
output[i] = values[indexes[i]]
```

Duplicate indexes are allowed; repeated reads simply copy the same source
value. The output position advances sequentially and is not indirectly
addressed.

## Contract

The exported symbol is `tsvc_vag_indexed_gather_copy`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, indexes[n], values[n]]`, with `n` in 1 through 64.
- Every index is in `[0,n-1]`; duplicates are allowed.
- Values are in `[-1,000,000, 1,000,000]`.
- Output contains `values[indexes[i]]` in ascending `i` order as little-endian
  signed i64 values. Success returns `n`; input is unchanged.
- Malformed input returns `-1`; a null output or capacity below `8*n` bytes
  returns `-2` without writing.

The profile's integer-valued inputs are exactly representable in the source's
binary64 `TYPE`. It retains the direct indexed gather and sequential copy but
excludes the source initializer, timing repetition, dummy call, and checksum.
This is distinct from `tsvc_s4117_pair_replicated_gather_map`, which reads a
fixed half-rate index and combines values arithmetically; from
`tsvc_s4114_reverse_index_gather_fma`, which uses a reverse-derived index in a
multiply-add; and from the indexed gather/scatter package, which writes
through an index rather than reading through one.

## Source and rights

The behavior reference is `vag` in `TSVC/tsc.inc`, lines 4929–4953, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4929). The assignment is at lines 4942–4945. Its launcher
[`TSVC/ControlLoops-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlLoops-dbl/tsc.c)
selects `TYPE double` and the `CONTROL_LOOPS` family. TSVC comments attribute
its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement the bounded gather-copy
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_vag_indexed_gather_copy_oracle.py`](../../tsvc_vag_indexed_gather_copy_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_vag_indexed_gather_copy.c`](../../../c/t/tsvc_vag_indexed_gather_copy.c) |
| C3 | [`tsvc_vag_indexed_gather_copy.c3`](../../../c3/t/tsvc_vag_indexed_gather_copy.c3) |
| C++ | [`tsvc_vag_indexed_gather_copy.cpp`](../../../cpp/t/tsvc_vag_indexed_gather_copy.cpp) |
| Elisa | [`tsvc_vag_indexed_gather_copy.elisa`](../../../elisa/t/tsvc_vag_indexed_gather_copy.elisa) |
| Nim | [`tsvc_vag_indexed_gather_copy.nim`](../../../nim/t/tsvc_vag_indexed_gather_copy.nim) |
| Odin | [`tsvc_vag_indexed_gather_copy.odin`](../../../odin/t/tsvc_vag_indexed_gather_copy.odin) |
| Rust | [`tsvc_vag_indexed_gather_copy.rs`](../../../rust/t/tsvc_vag_indexed_gather_copy.rs) |
| V | [`tsvc_vag_indexed_gather_copy.v`](../../../v/t/tsvc_vag_indexed_gather_copy.v) |
| Zig | [`tsvc_vag_indexed_gather_copy.zig`](../../../zig/t/tsvc_vag_indexed_gather_copy.zig) |
