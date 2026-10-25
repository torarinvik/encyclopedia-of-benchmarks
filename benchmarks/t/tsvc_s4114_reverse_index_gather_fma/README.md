# TSVC s4114 reverse-index gather FMA

This package is a bounded, clean-room one-sweep profile of TSVC s4114 in the
IndirectAddressing-dbl family. It writes a dense output vector, combining each
B and D element with a C element selected by a caller index and a reversed
lookup:

A[i] = B[i] + C[n - 1 - IP[i]] * D[i].

This is distinct from s4113/s491's indirect left-hand-side scatter and from
s4117's fixed half-rate C gather. The index is validated before any output is
written.

## Contract

The exported function is tsvc_s4114_reverse_index_gather_fma, using the
i64_array_bytes_output ABI.

- Input is [n, IP[n], B[n], C[n], D[n]], with n in 1..64.
- Each IP value is an integer in [0,n-1]. B, C, and D values are in [-2,2].
- Visit i in ascending order and write B[i] + C[n-1-IP[i]]*D[i]. Integer
  products and sums remain exact in the source's double type and fit signed i64.
- Emit A[n] as little-endian signed i64 values and return n. Required capacity
  is 8*n bytes. Input is unchanged.
- Malformed input returns -1; null output or insufficient capacity returns
  -2 without writes.

The source takes n1 as its lower-bound scalar. The launcher passes n1=1, so
this profile fixes the first index to zero and executes the complete sweep.
The source's k += 5 statement follows the output write and k is not read again,
so that dead update is omitted. Timing repetitions, initialization, dummy
calls, and checksums are excluded.

## Source and rights

The behavior reference is s4114 at lines 4758–4783 of
[TSVC/tsc.inc](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4758),
pinned to LAC-DCC Benchmarks commit
5d7b75df749241efa7a6e6f5be613d3fcc5cce38. Its initialization is at lines
728–732 and the launcher call is at line 5493. The launcher is
[TSVC/IndirectAddressing-dbl/tsc.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/IndirectAddressing-dbl/tsc.c),
which selects TYPE double and uses run options 12500 14. TSVC comments
attribute its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, Test Suite for Vectorizing Compilers.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [LICENSE.txt](LICENSE.txt).

The independent oracle and fixed workload are
[tsvc_s4114_reverse_index_gather_fma_oracle.py](../../tsvc_s4114_reverse_index_gather_fma_oracle.py)
and [workload.json](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [tsvc_s4114_reverse_index_gather_fma.c](../../../c/t/tsvc_s4114_reverse_index_gather_fma.c) |
| C3 | [tsvc_s4114_reverse_index_gather_fma.c3](../../../c3/t/tsvc_s4114_reverse_index_gather_fma.c3) |
| C++ | [tsvc_s4114_reverse_index_gather_fma.cpp](../../../cpp/t/tsvc_s4114_reverse_index_gather_fma.cpp) |
| Elisa | [tsvc_s4114_reverse_index_gather_fma.elisa](../../../elisa/t/tsvc_s4114_reverse_index_gather_fma.elisa) |
| Nim | [tsvc_s4114_reverse_index_gather_fma.nim](../../../nim/t/tsvc_s4114_reverse_index_gather_fma.nim) |
| Odin | [tsvc_s4114_reverse_index_gather_fma.odin](../../../odin/t/tsvc_s4114_reverse_index_gather_fma.odin) |
| Rust | [tsvc_s4114_reverse_index_gather_fma.rs](../../../rust/t/tsvc_s4114_reverse_index_gather_fma.rs) |
| V | [tsvc_s4114_reverse_index_gather_fma.v](../../../v/t/tsvc_s4114_reverse_index_gather_fma.v) |
| Zig | [tsvc_s4114_reverse_index_gather_fma.zig](../../../zig/t/tsvc_s4114_reverse_index_gather_fma.zig) |
