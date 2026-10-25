# TSVC s162 guarded shifted FMA

This package is a bounded, clean-room one-sweep profile of TSVC s162 in the
ControlFlow-dbl family. A single scalar guard controls whether the loop runs.
When enabled, each prefix element is replaced with a one-slot lookahead from
A plus the pointwise product of B and C:

A[i] = A[i+1] + B[i] * C[i], for i=0..n-2.

The final A element remains unchanged. This differs from s131's unscaled
lookahead addition and from s243's three ordered updates across A and B.

## Contract

The exported symbol is tsvc_s162_guarded_shifted_fma, using the
i64_array_bytes_output ABI.

- Input is [n, k, A[n], B[n], C[n]], with n in 1..64 and k either 0 or 1.
- Array values are in [-2,2]. The products and sums remain exact small integers
  in the source's double type and fit signed i64.
- If k is zero, preserve A unchanged, following the source's false guard.
- If k is one, visit i from zero through n-2 in ascending order and write
  A[i] = A[i+1] + B[i]*C[i]. Leave A[n-1] unchanged.
- Emit final A as little-endian signed i64 values and return n. Required
  capacity is 8*n bytes. Inputs are unchanged.
- Malformed input returns -1; null output or insufficient capacity returns
  -2 without writes.

The pinned launcher passes k=1. The source's loop bound is LEN-1 regardless
of k, so this profile restricts positive k to one; larger shifts could read
past the source array. The k=0 profile exercises the branch-off no-op.
Timing repetitions, initialization, dummy calls, and checksums are excluded.
The source initializes A to one and B/C to reciprocal-index values, while this
package supplies bounded arrays to expose the state transition directly.

## Source and rights

The behavior reference is s162 at lines 1637–1659 of
[TSVC/tsc.inc](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1637),
pinned to LAC-DCC Benchmarks commit
5d7b75df749241efa7a6e6f5be613d3fcc5cce38. Initialization is at lines
347–350. The launcher is
[TSVC/ControlFlow-dbl/tsc.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/tsc.c),
which selects TYPE double and uses run options 2325 14. Its main routine
passes n1=1 to s162. TSVC comments attribute its non-four-digit codelets to
David Callahan, Jack Dongarra, and David Levine, Test Suite for Vectorizing
Compilers.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [LICENSE.txt](LICENSE.txt).

The independent oracle and fixed workload are
[tsvc_s162_guarded_shifted_fma_oracle.py](../../tsvc_s162_guarded_shifted_fma_oracle.py)
and [workload.json](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [tsvc_s162_guarded_shifted_fma.c](../../../c/t/tsvc_s162_guarded_shifted_fma.c) |
| C3 | [tsvc_s162_guarded_shifted_fma.c3](../../../c3/t/tsvc_s162_guarded_shifted_fma.c3) |
| C++ | [tsvc_s162_guarded_shifted_fma.cpp](../../../cpp/t/tsvc_s162_guarded_shifted_fma.cpp) |
| Elisa | [tsvc_s162_guarded_shifted_fma.elisa](../../../elisa/t/tsvc_s162_guarded_shifted_fma.elisa) |
| Nim | [tsvc_s162_guarded_shifted_fma.nim](../../../nim/t/tsvc_s162_guarded_shifted_fma.nim) |
| Odin | [tsvc_s162_guarded_shifted_fma.odin](../../../odin/t/tsvc_s162_guarded_shifted_fma.odin) |
| Rust | [tsvc_s162_guarded_shifted_fma.rs](../../../rust/t/tsvc_s162_guarded_shifted_fma.rs) |
| V | [tsvc_s162_guarded_shifted_fma.v](../../../v/t/tsvc_s162_guarded_shifted_fma.v) |
| Zig | [tsvc_s162_guarded_shifted_fma.zig](../../../zig/t/tsvc_s162_guarded_shifted_fma.zig) |
