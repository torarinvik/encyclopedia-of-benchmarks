# TSVC s471 ordered two-vector map

This bounded profile preserves the `s471` loop order. For each ascending
index, it writes `X[i] = B[i] + D[i]*D[i]`, calls the source's empty helper,
then updates `B[i] = C[i] + D[i]*E[i]`. Both final vectors are returned, so the
X write remains observable. On later passes X reads the B value written by the
preceding pass; the B update itself reaches a fixed point after each index's
first update.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `tsvc_s471_ordered_two_vector_map`.
- Input: `[n, passes, B[n], C[n], D[n], E[n]]`, with `1 <= n <= 32`,
  `1 <= passes <= 4`, and data values in `[-2,2]`.
- Exact input length is `2+4*n`. Output is final X followed by final B, both
  little-endian signed i64 vectors; success returns `16*n` bytes. Invalid
  input returns `-1`; null output or insufficient capacity returns `-2`
  without writes.
- Values remain integral and exactly represented in both TSVC precisions;
  `X` remains within `[-6,10]` and final B within `[-6,6]`.
- This profile exposes the loop body with explicit input arrays. It excludes
  the launcher's timing/checker wrapper and the no-op `s471s` call.

## Provenance and rights

Pinned source: `lac-dcc/Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, symbol `s471`
(lines 4819–4848), selected by `GlobalDataFlow-dbl/info.sh` and
`GlobalDataFlow-flt/info.sh`. No explicit TSVC modification or redistribution
grant was found in reviewed pinned materials; these are clean-room ports.
See [LICENSE.txt](LICENSE.txt).

Independent oracle: [`benchmarks/tsvc_s471_ordered_two_vector_map_oracle.py`](../../tsvc_s471_ordered_two_vector_map_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [C](../../../c/t/tsvc_s471_ordered_two_vector_map.c) |
| C3 | [C3](../../../c3/t/tsvc_s471_ordered_two_vector_map.c3) |
| C++ | [C++](../../../cpp/t/tsvc_s471_ordered_two_vector_map.cpp) |
| Elisa | [Elisa](../../../elisa/t/tsvc_s471_ordered_two_vector_map.elisa) |
| Nim | [Nim](../../../nim/t/tsvc_s471_ordered_two_vector_map.nim) |
| Odin | [Odin](../../../odin/t/tsvc_s471_ordered_two_vector_map.odin) |
| Rust | [Rust](../../../rust/t/tsvc_s471_ordered_two_vector_map.rs) |
| V | [V](../../../v/t/tsvc_s471_ordered_two_vector_map.v) |
| Zig | [Zig](../../../zig/t/tsvc_s471_ordered_two_vector_map.zig) |
