# TSVC s293 first-element broadcast

This package profiles TSVC's `s293` loop body. The loop visits `i` in ascending
order and assigns the original `A[0]` value to every `A[i]`. The profile keeps
the source's array broadcast operation and exposes the full resulting array.

## Contract

- Export `tsvc_s293_first_element_broadcast` with the `i64_array_bytes_output`
  ABI.
- Input is `[n,A[0..n)]`, with `1<=n<=32`, exact length `1+n`, and values in
  `[-8,8]`.
- Output contains `n` copies of the original `A[0]`, encoded as little-endian
  signed i64 values; success returns `8*n` bytes.
- Invalid or null input returns `-1`; null output or insufficient capacity
  returns `-2` without writes. Input is not modified.
- The source's `TYPE` is selected by its double/float launcher. The bounded
  integer inputs are exact in both formats.

This explicit frame profiles the loop body and does not recreate the launcher's
initialized global arrays, repeated timing loop, or checker wrapper.

## Provenance and rights

Pinned source: `lac-dcc/Benchmarks`, commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, s293 lines
3358–3380. The selected launchers are `CrossingThresholds-dbl` and
`CrossingThresholds-flt`. No explicit modification or redistribution grant was
found in the reviewed pinned source material; ports are clean-room.
See [LICENSE.txt](LICENSE.txt).

Independent oracle: [`benchmarks/tsvc_s293_first_element_broadcast_oracle.py`](../../tsvc_s293_first_element_broadcast_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [C](../../../c/t/tsvc_s293_first_element_broadcast.c) |
| C3 | [C3](../../../c3/t/tsvc_s293_first_element_broadcast.c3) |
| C++ | [C++](../../../cpp/t/tsvc_s293_first_element_broadcast.cpp) |
| Elisa | [Elisa](../../../elisa/t/tsvc_s293_first_element_broadcast.elisa) |
| Nim | [Nim](../../../nim/t/tsvc_s293_first_element_broadcast.nim) |
| Odin | [Odin](../../../odin/t/tsvc_s293_first_element_broadcast.odin) |
| Rust | [Rust](../../../rust/t/tsvc_s293_first_element_broadcast.rs) |
| V | [V](../../../v/t/tsvc_s293_first_element_broadcast.v) |
| Zig | [Zig](../../../zig/t/tsvc_s293_first_element_broadcast.zig) |
