# TSVC s2111 wavefront addition recurrence

This package is a bounded, clean-room profile of the row-major in-place
recurrence in TSVC s2111. For each interior cell, it replaces the current value
with the sum of its already-updated left neighbor and the value directly above:

    A[row][col] = A[row][col - 1] + A[row - 1][col]

Rows and columns are visited in ascending order, beginning at index one. The
top row and left column remain unchanged. This is a two-dimensional wavefront
recurrence; it is distinct from a summed-area table, which adds original cell
values and subtracts the diagonal prefix.

## Contract

The exported symbol is `tsvc_s2111_wavefront_add_recurrence`, using the
`i64_array_bytes_output` ABI:

- Input is `[side, passes, matrix[side*side]]`, flattened in row-major order.
- `side` is 2 through 8; `passes` is 1 through 4.
- Seed values are integers in `[-8,8]` and are exact in the source's binary64
  arithmetic.
- Each pass updates only interior cells in source order. The recurrence
  overwrites each interior value; it does not add the old value.
- On success, write the complete final matrix as little-endian signed i64
  values and return `side*side`.
- Malformed input returns `-1`; null output or capacity below `8*side*side`
  bytes returns `-2` without writing output.

The pinned launcher initializes the matrix to all zeros, so its unmodified
`s2111` run remains zero and the checker substitutes a sentinel value. The
package uses caller-provided boundary seeds as a bounded profile projection so
the recurrence itself is observable. For a fixed boundary, one full pass
reaches the same interior state on subsequent passes; the `passes` field
preserves a bounded repetition control matching the source loop structure.

The independent oracle and fixed cases are
[`tsvc_s2111_wavefront_add_recurrence_oracle.py`](../../tsvc_s2111_wavefront_add_recurrence_oracle.py)
and [`workload.json`](workload.json).

## Source and rights

The behavior reference is s2111 in `TSVC/tsc.inc`, lines 3285–3311, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3285). The loop is at lines 3293–3297 and the launcher family is
`TSVC/CrossingThresholds-dbl`. The source includes a row-major sweep over
`aa[j][i] = aa[j][i-1] + aa[j-1][i]`, followed by a full-matrix checksum.
TSVC comments attribute non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement this bounded recurrence
and reuse no upstream code or comments; no upstream license or endorsement is
claimed. See [`LICENSE.txt`](LICENSE.txt).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s2111_wavefront_add_recurrence.c`](../../../c/t/tsvc_s2111_wavefront_add_recurrence.c) |
| C3 | [`tsvc_s2111_wavefront_add_recurrence.c3`](../../../c3/t/tsvc_s2111_wavefront_add_recurrence.c3) |
| C++ | [`tsvc_s2111_wavefront_add_recurrence.cpp`](../../../cpp/t/tsvc_s2111_wavefront_add_recurrence.cpp) |
| Elisa | [`tsvc_s2111_wavefront_add_recurrence.elisa`](../../../elisa/t/tsvc_s2111_wavefront_add_recurrence.elisa) |
| Nim | [`tsvc_s2111_wavefront_add_recurrence.nim`](../../../nim/t/tsvc_s2111_wavefront_add_recurrence.nim) |
| Odin | [`tsvc_s2111_wavefront_add_recurrence.odin`](../../../odin/t/tsvc_s2111_wavefront_add_recurrence.odin) |
| Rust | [`tsvc_s2111_wavefront_add_recurrence.rs`](../../../rust/t/tsvc_s2111_wavefront_add_recurrence.rs) |
| V | [`tsvc_s2111_wavefront_add_recurrence.v`](../../../v/t/tsvc_s2111_wavefront_add_recurrence.v) |
| Zig | [`tsvc_s2111_wavefront_add_recurrence.zig`](../../../zig/t/tsvc_s2111_wavefront_add_recurrence.zig) |
