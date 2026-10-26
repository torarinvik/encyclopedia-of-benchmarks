# TSVC s1111 stride-two polynomial map

This clean-room profile preserves the pinned source expression for each `i`:

    A[2*i] = C[i]*B[i] + D[i]*B[i] + C[i]*C[i] + D[i]*B[i] + D[i]*C[i]

The source visits `i` in ascending order and writes only even A positions; odd
positions are retained. The arithmetic expression is left-associated and
contains the source's repeated `D[i]*B[i]` term. This is distinct from s111's
neighbor update and from pointwise FMA profiles.

## Contract

Export `tsvc_s1111_stride_two_polynomial_map` with `i64_array_bytes_output`.
Input is `[n, A[2*n], B[n], C[n], D[n]]`; `n` is 1..32 and all values are
integers in [-2,2]. Output is final A, little-endian signed i64, and success
returns `2*n` elements. Malformed input returns -1. Null output or capacity
below `16*n` returns -2 without writes; malformed-input validation comes first.
The bounded products and five-term sums are exact in both TSVC float precision
families and lie in [-20,20].

The independent oracle and fixtures are
[`tsvc_s1111_stride_two_polynomial_map_oracle.py`](../../tsvc_s1111_stride_two_polynomial_map_oracle.py)
and [`workload.json`](workload.json).

## Source and rights

Source is `s1111` in `TSVC/tsc.inc`, lines 871–893, pinned to LAC-DCC
[`Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L871), selected in `TSVC/LinearDependence-dbl/info.sh` (`3570 14`; float uses `3570 5`). The package exposes caller-provided arrays rather than the source initializer/checksum harness. TSVC comments attribute its codelets to David Callahan, Jack Dongarra, and David Levine.

No explicit redistribution grant was found in the pinned repository material reviewed. The nine ports are independent clean-room implementations and reuse no upstream source or comments; no upstream license or endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt).
