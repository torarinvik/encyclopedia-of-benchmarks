# TSVC s2102 identity matrix initialization

This package is a bounded, clean-room profile of TSVC s2102. It initializes an
N-by-N matrix column by column: clear every row in the current column, then set
the matching diagonal entry to one. The final row-major matrix is the identity.

## Contract

The exported symbol is `tsvc_s2102_identity_matrix_initialize`, using the
`i64_array_bytes_output` ABI:

- Input is `[side, passes]`, with `side` from 1 through 8 and `passes` from 1
  through 8.
- Each pass visits columns in ascending order, clears rows in ascending order,
  then writes the diagonal element for that column.
- On success, write the full row-major matrix as little-endian signed i64
  values and return `side*side`.
- Malformed input returns `-1`; null output or capacity below `8*side*side`
  bytes returns `-2` without writing output.

The source resets each column before setting its diagonal, so repeated passes
produce the same identity matrix. The package retains a small explicit pass
count as a bounded loop-workload control. The pinned checker reports a matrix
sum; this package exposes the complete matrix state so each initialized cell is
observable.

The independent oracle and fixed cases are
[`tsvc_s2102_identity_matrix_initialize_oracle.py`](../../tsvc_s2102_identity_matrix_initialize_oracle.py)
and [`workload.json`](workload.json).

## Source and rights

The behavior reference is s2102 in `TSVC/tsc.inc`, lines 3257–3281, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3257). Its loop is at lines 3267–3273: for each column `i`, clear `aa[j][i]` for all `j`, then assign `aa[i][i] = 1`. The launcher family is `TSVC/CrossingThresholds-dbl`; the family selects binary64 `TYPE`. This initializer is distinct from the existing s2101 diagonal FMA, which updates diagonal values from three input matrices. TSVC comments attribute non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement this bounded operation
and reuse no upstream code or comments; no upstream license or endorsement is
claimed. See [`LICENSE.txt`](LICENSE.txt).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s2102_identity_matrix_initialize.c`](../../../c/t/tsvc_s2102_identity_matrix_initialize.c) |
| C3 | [`tsvc_s2102_identity_matrix_initialize.c3`](../../../c3/t/tsvc_s2102_identity_matrix_initialize.c3) |
| C++ | [`tsvc_s2102_identity_matrix_initialize.cpp`](../../../cpp/t/tsvc_s2102_identity_matrix_initialize.cpp) |
| Elisa | [`tsvc_s2102_identity_matrix_initialize.elisa`](../../../elisa/t/tsvc_s2102_identity_matrix_initialize.elisa) |
| Nim | [`tsvc_s2102_identity_matrix_initialize.nim`](../../../nim/t/tsvc_s2102_identity_matrix_initialize.nim) |
| Odin | [`tsvc_s2102_identity_matrix_initialize.odin`](../../../odin/t/tsvc_s2102_identity_matrix_initialize.odin) |
| Rust | [`tsvc_s2102_identity_matrix_initialize.rs`](../../../rust/t/tsvc_s2102_identity_matrix_initialize.rs) |
| V | [`tsvc_s2102_identity_matrix_initialize.v`](../../../v/t/tsvc_s2102_identity_matrix_initialize.v) |
| Zig | [`tsvc_s2102_identity_matrix_initialize.zig`](../../../zig/t/tsvc_s2102_identity_matrix_initialize.zig) |
