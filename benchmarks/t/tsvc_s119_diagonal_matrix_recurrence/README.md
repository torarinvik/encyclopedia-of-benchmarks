# TSVC s119 diagonal matrix recurrence

A bounded clean-room profile of the pinned TSVC `s119` kernel. It sweeps a
row-major square matrix in ascending row and column order and overwrites each
interior element with the value at its northwest diagonal predecessor plus the
matching element from a second matrix:

    A[row][col] = A[row - 1][col - 1] + B[row][col]

The top row and left column are preserved. Because the predecessor is read
from the in-place matrix, source order is part of the contract. This diagonal
recurrence differs from s2111's two-neighbor left-plus-above wavefront.

## Contract

The symbol is `tsvc_s119_diagonal_matrix_recurrence`, with the
`i64_array_bytes_output` ABI. Input is `[side, passes, A[side*side],
B[side*side]]`, each matrix row-major. `side` is 2..8, `passes` is 1..4, and
all seed values are in [-2,2]. On success the complete final A matrix is
written as little-endian signed i64 values; the return value is the element
count `side*side`. Malformed input returns -1. Null output or capacity below
`8*side*side` returns -2 without writing. Validation precedes capacity checks.

The bounded profile uses caller-provided seeds because the pinned initializer
sets the matrices to zeros, which would make the recurrence unobservable. The
source checks the full matrix after each call. For a fixed B and boundary,
one row-major pass establishes the diagonal prefix and further passes are
idempotent. Intermediate values remain within [-16,16].

The independent oracle is
[`tsvc_s119_diagonal_matrix_recurrence_oracle.py`](../../tsvc_s119_diagonal_matrix_recurrence_oracle.py);
fixtures and exact bounds are in [`workload.json`](workload.json).

## Provenance and rights

Source: `s119` in `TSVC/tsc.inc`, lines 1150–1177, at LAC-DCC
[`Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1150). The selected launcher is `TSVC/LinearDependence-dbl/info.sh` (`RUN_OPTIONS="3570 14"`); the float launcher uses `3570 5`. The codelet runs in ascending `i`, then ascending `j`, and calls the full-matrix checker. TSVC comments attribute codelets to David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit redistribution grant was found in the pinned repository material reviewed. These are independent clean-room ports and reuse no upstream code or comments; no upstream license or endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt).

## Ports

C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig implementations are provided under the matching `*/t/tsvc_s119_diagonal_matrix_recurrence.*` paths.
