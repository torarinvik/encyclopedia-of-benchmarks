# TSVC s318 strided absolute maximum with index

This package is a bounded, clean-room profile of TSVC `s318` from the
`Reductions-dbl` launcher family. It scans a strided physical array, compares
absolute magnitudes, and returns the greatest sampled magnitude and its first
logical sample index. Strictly greater updates preserve the first index on
ties.

## Contract

The exported symbol is `tsvc_s318_strided_absolute_maximum_with_index`, using
the `i64_array_bytes_output` ABI:

- Input is `[logical_count, stride, physical_values...]`.
- `logical_count` is 1 through 64; `stride` is 1 through 4.
- The physical value count must equal `1 + (logical_count - 1) * stride`.
- The scan samples `physical_values[i * stride]` for `i` in
  `0..logical_count`; all physical values, including skipped gap values, must
  lie in `[-1,000,000, 1,000,000]`.
- On success, write the maximum sampled absolute magnitude followed by its
  first zero-based logical index as two signed 64-bit little-endian integers;
  return `2`.
- Malformed input returns `-1`. A null output or capacity below 16 bytes
  returns `-2` without writing output.

The source code's `k` progression corresponds to these `i * stride` sample
positions. The bounded profile explicitly sizes the backing array to contain
all requested samples; this avoids out-of-bounds accesses for non-unit strides
in the original fixed-`LEN` global array. Integer inputs are exactly
representable in the source's binary64 `TYPE` and make its absolute-value
comparisons unambiguous. The stride is an explicit profile input because the
codelet accepts `inc` as a parameter; this package does not claim to reproduce
an unspecified external launcher's chosen `inc`.

This result contract is distinct from `abs_max`, which returns the signed
element selected by magnitude but not its logical index; it is also distinct
from `tsvc_s315_maximum_with_index`, which finds the greatest signed value.

## Source and rights

The behavior reference is `s318` in `TSVC/tsc.inc`, lines 3574–3610, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3574). The scan and index update are
at lines 3587–3602. Initialization sets `a[LEN-1]` to `-2` at lines 574–576.
The launcher file [`TSVC/Reductions-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Reductions-dbl/tsc.c)
selects `TYPE double`. TSVC comments attribute its non-four-digit codelets to
David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement the bounded scan and
reuse no upstream source code or comments. No upstream license or endorsement
is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s318_strided_absolute_maximum_with_index_oracle.py`](../../tsvc_s318_strided_absolute_maximum_with_index_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s318_strided_absolute_maximum_with_index.c`](../../../c/t/tsvc_s318_strided_absolute_maximum_with_index.c) |
| C3 | [`tsvc_s318_strided_absolute_maximum_with_index.c3`](../../../c3/t/tsvc_s318_strided_absolute_maximum_with_index.c3) |
| C++ | [`tsvc_s318_strided_absolute_maximum_with_index.cpp`](../../../cpp/t/tsvc_s318_strided_absolute_maximum_with_index.cpp) |
| Elisa | [`tsvc_s318_strided_absolute_maximum_with_index.elisa`](../../../elisa/t/tsvc_s318_strided_absolute_maximum_with_index.elisa) |
| Nim | [`tsvc_s318_strided_absolute_maximum_with_index.nim`](../../../nim/t/tsvc_s318_strided_absolute_maximum_with_index.nim) |
| Odin | [`tsvc_s318_strided_absolute_maximum_with_index.odin`](../../../odin/t/tsvc_s318_strided_absolute_maximum_with_index.odin) |
| Rust | [`tsvc_s318_strided_absolute_maximum_with_index.rs`](../../../rust/t/tsvc_s318_strided_absolute_maximum_with_index.rs) |
| V | [`tsvc_s318_strided_absolute_maximum_with_index.v`](../../../v/t/tsvc_s318_strided_absolute_maximum_with_index.v) |
| Zig | [`tsvc_s318_strided_absolute_maximum_with_index.zig`](../../../zig/t/tsvc_s318_strided_absolute_maximum_with_index.zig) |
