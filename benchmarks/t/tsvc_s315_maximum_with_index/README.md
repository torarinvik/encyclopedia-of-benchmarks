# TSVC s315 maximum with index

This package is a bounded, clean-room profile of TSVC `s315` from the
`Reductions-dbl` launcher family. It scans one array and returns both its
maximum value and the index of the first occurrence:

```text
maximum = values[0]
index = 0
for i from 1 to n-1:
    if values[i] > maximum:
        maximum = values[i]
        index = i
```

The strict comparison preserves the lowest index when the maximum is tied.
The repository has value-only maximum scans, but no equivalent argmax result
contract. TSVC `s3110` records a maximum and its two-dimensional coordinates;
for a row-major flattening those coordinates are a shape-specific view of the
same maximum-with-first-index scan, so it is not treated as a separate core.

## Contract

The exported symbol is `tsvc_s315_maximum_with_index`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, values[n]]`, with `n` in `1..64`.
- Each value is in `[-1,000,000, 1,000,000]`.
- On success, write two signed 64-bit little-endian integers: maximum value,
  then its first zero-based index. Return `2`.
- A malformed input returns `-1`; a null output or capacity below 16 bytes
  returns `-2` without writing output.
- Input values are not modified.

The maximum input length is 65 integers. The numeric bounds are substantially
within the exact integer range of the source's binary64 `TYPE double` profile.

## Source and rights

The behavior reference is `s315` in `TSVC/tsc.inc`, lines 3477–3510, pinned
to LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3477).
The scan is at lines 3493–3500; the source workload overwrites its input using
`(i*7)%LEN` at lines 3486–3488. The launcher is
[`TSVC/Reductions-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Reductions-dbl/tsc.c),
which selects `TYPE double` and the reductions family. TSVC comments attribute
its non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s315_maximum_with_index_oracle.py`](../../tsvc_s315_maximum_with_index_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s315_maximum_with_index.c`](../../../c/t/tsvc_s315_maximum_with_index.c) |
| C3 | [`tsvc_s315_maximum_with_index.c3`](../../../c3/t/tsvc_s315_maximum_with_index.c3) |
| C++ | [`tsvc_s315_maximum_with_index.cpp`](../../../cpp/t/tsvc_s315_maximum_with_index.cpp) |
| Elisa | [`tsvc_s315_maximum_with_index.elisa`](../../../elisa/t/tsvc_s315_maximum_with_index.elisa) |
| Nim | [`tsvc_s315_maximum_with_index.nim`](../../../nim/t/tsvc_s315_maximum_with_index.nim) |
| Odin | [`tsvc_s315_maximum_with_index.odin`](../../../odin/t/tsvc_s315_maximum_with_index.odin) |
| Rust | [`tsvc_s315_maximum_with_index.rs`](../../../rust/t/tsvc_s315_maximum_with_index.rs) |
| V | [`tsvc_s315_maximum_with_index.v`](../../../v/t/tsvc_s315_maximum_with_index.v) |
| Zig | [`tsvc_s315_maximum_with_index.zig`](../../../zig/t/tsvc_s315_maximum_with_index.zig) |
