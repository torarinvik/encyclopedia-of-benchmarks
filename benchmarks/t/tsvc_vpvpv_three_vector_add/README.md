# TSVC ControlLoops `vpvpv` three-vector update

This package profiles the pinned `vpvpv` loop body. Each ascending index and
pass performs `A[i] += B[i] + C[i]`; B and C remain unchanged, and the final A
vector is observable.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `tsvc_vpvpv_three_vector_add`.
- Input: `[n, passes, A[n], B[n], C[n]]`; `1 <= n <= 32`, `1 <= passes <= 4`,
  and every element is in `[-2,2]`.
- Exact input length is `2+3*n`. Output is final A as little-endian signed
  64-bit values, with `8*n` bytes on success. Invalid input returns `-1`;
  null output or insufficient capacity returns `-2` without writes.
- The bounded integral result is within `[-18,18]`, exactly representable in
  binary32 and binary64. The frame isolates the loop body from launcher timing,
  initialization, and checking.

## Provenance and rights

Pinned source: `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, symbol `vpvpv`
(lines 5384–5409), invoked by `ControlLoops-dbl/info.sh` and
`ControlLoops-flt/info.sh`. This three-input vector update is not the two-input
matrix copy or dense SAXPY profile. No explicit TSVC modification or
redistribution grant was found; the ports are clean-room. See [LICENSE.txt](LICENSE.txt).

Independent oracle: [`benchmarks/tsvc_vpvpv_three_vector_add_oracle.py`](../../tsvc_vpvpv_three_vector_add_oracle.py).

## Ports

C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig ports are provided under their
respective `t/` directories; each exports the symbol above.
