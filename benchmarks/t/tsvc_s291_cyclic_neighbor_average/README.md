# TSVC s291 cyclic neighbor average

This package implements a bounded, clean-room profile of TSVC `s291` from the
`CrossingThresholds-dbl` launcher family. For each input position `i`, it
averages the current value and its cyclic predecessor:

```text
out[i] = (values[i] + values[(i - 1) mod n]) / 2
```

The final input value is the predecessor of position zero. This is a fixed
two-point cyclic stencil; it differs from the local moving-average benchmarks,
which use trailing windows and do not wrap the first output to the final input.

## Contract

The exported symbol is `tsvc_s291_cyclic_neighbor_average`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, values[0..n]]`, with `n` in 2 through 64.
- Values are in `[-1,000,000, 1,000,000]`.
- On success, write `n` signed 64-bit little-endian integers equal to
  `2 * out[i]`, then return `n` (the number of output elements).
- The factor of two represents half-integer averages exactly: each stored
  integer is simply `values[i] + values[(i - 1) mod n]`.
- Malformed input returns `-1`; a null output or capacity below `8*n` bytes
  returns `-2` without writing output.

The operation reads from an immutable input sequence and emits the updated A
sequence separately. The profile uses bounded integers, all exactly
representable by the source's binary64 `TYPE`.

## Source and rights

The behavior reference is `s291` in `TSVC/tsc.inc`, lines 3145–3170, pinned to
LAC-DCC `Benchmarks` commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3145). The loop initializes its prior index to `LEN-1`, reads `b[i]` and `b[im1]`, then assigns `im1=i` (lines 3157–3162). The launcher
[`TSVC/CrossingThresholds-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/CrossingThresholds-dbl/tsc.c)
selects `TYPE double`. TSVC comments attribute its non-four-digit codelets to
David Callahan, Jack Dongarra, and David Levine, *Test Suite for Vectorizing
Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement the bounded cyclic
stencil and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s291_cyclic_neighbor_average_oracle.py`](../../tsvc_s291_cyclic_neighbor_average_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s291_cyclic_neighbor_average.c`](../../../c/t/tsvc_s291_cyclic_neighbor_average.c) |
| C3 | [`tsvc_s291_cyclic_neighbor_average.c3`](../../../c3/t/tsvc_s291_cyclic_neighbor_average.c3) |
| C++ | [`tsvc_s291_cyclic_neighbor_average.cpp`](../../../cpp/t/tsvc_s291_cyclic_neighbor_average.cpp) |
| Elisa | [`tsvc_s291_cyclic_neighbor_average.elisa`](../../../elisa/t/tsvc_s291_cyclic_neighbor_average.elisa) |
| Nim | [`tsvc_s291_cyclic_neighbor_average.nim`](../../../nim/t/tsvc_s291_cyclic_neighbor_average.nim) |
| Odin | [`tsvc_s291_cyclic_neighbor_average.odin`](../../../odin/t/tsvc_s291_cyclic_neighbor_average.odin) |
| Rust | [`tsvc_s291_cyclic_neighbor_average.rs`](../../../rust/t/tsvc_s291_cyclic_neighbor_average.rs) |
| V | [`tsvc_s291_cyclic_neighbor_average.v`](../../../v/t/tsvc_s291_cyclic_neighbor_average.v) |
| Zig | [`tsvc_s291_cyclic_neighbor_average.zig`](../../../zig/t/tsvc_s291_cyclic_neighbor_average.zig) |
