# TSVC s4117 pair-replicated gather map

This package is a bounded, clean-room one-sweep profile of TSVC s4117 in the
IndirectAddressing-dbl family. It computes an output vector from a dense B and
D pair plus a half-rate C gather: A[i] = B[i] + C[floor(i/2)] * D[i]. Each C
element is used by two adjacent output positions; for odd n, the final C
element is used once.

## Contract

The exported function is tsvc_s4117_pair_replicated_gather_map and uses the
i64_array_bytes_output ABI.

- Input is [n, B[n], C[ceil(n/2)], D[n]], with n in 1..64.
- Every B, C, and D value is in [-2,2]. The resulting values remain exact
  small integers in the source's double type and fit signed i64.
- Visit i in ascending order and write B[i] + C[i/2] * D[i], where i/2 is
  integer division.
- Emit A[n] as little-endian signed i64 values and return n. Required capacity
  is 8*n bytes. Inputs are unchanged.
- Malformed input returns -1; null output or insufficient capacity returns
  -2 without writes.

The source initializes A, B, C, and D, but A is overwritten at every index by
the codelet. This package therefore takes only the three read arrays. It
preserves the full-length loop and excludes timing repetitions, initialization,
dummy calls, and checksums. The pinned launcher uses IndirectAddressing-dbl,
TYPE double, and run options 12500 14.

## Source and rights

The source reference is s4117 at lines 4848–4870 of
[TSVC/tsc.inc](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4848),
pinned to LAC-DCC Benchmarks commit
5d7b75df749241efa7a6e6f5be613d3fcc5cce38. Its input initialization is at
lines 740–743. The launcher is
[TSVC/IndirectAddressing-dbl/tsc.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/IndirectAddressing-dbl/tsc.c).
TSVC comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, Test Suite for Vectorizing Compilers.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [LICENSE.txt](LICENSE.txt).

The independent oracle and fixed workload are
[tsvc_s4117_pair_replicated_gather_map_oracle.py](../../tsvc_s4117_pair_replicated_gather_map_oracle.py)
and [workload.json](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [tsvc_s4117_pair_replicated_gather_map.c](../../../c/t/tsvc_s4117_pair_replicated_gather_map.c) |
| C3 | [tsvc_s4117_pair_replicated_gather_map.c3](../../../c3/t/tsvc_s4117_pair_replicated_gather_map.c3) |
| C++ | [tsvc_s4117_pair_replicated_gather_map.cpp](../../../cpp/t/tsvc_s4117_pair_replicated_gather_map.cpp) |
| Elisa | [tsvc_s4117_pair_replicated_gather_map.elisa](../../../elisa/t/tsvc_s4117_pair_replicated_gather_map.elisa) |
| Nim | [tsvc_s4117_pair_replicated_gather_map.nim](../../../nim/t/tsvc_s4117_pair_replicated_gather_map.nim) |
| Odin | [tsvc_s4117_pair_replicated_gather_map.odin](../../../odin/t/tsvc_s4117_pair_replicated_gather_map.odin) |
| Rust | [tsvc_s4117_pair_replicated_gather_map.rs](../../../rust/t/tsvc_s4117_pair_replicated_gather_map.rs) |
| V | [tsvc_s4117_pair_replicated_gather_map.v](../../../v/t/tsvc_s4117_pair_replicated_gather_map.v) |
| Zig | [tsvc_s4117_pair_replicated_gather_map.zig](../../../zig/t/tsvc_s4117_pair_replicated_gather_map.zig) |
