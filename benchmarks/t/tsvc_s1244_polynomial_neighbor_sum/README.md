# TSVC s1244 polynomial neighbor sum

This package is a bounded, clean-room, one-sweep profile of TSVC `s1244` in
the `NodeSplitting-dbl` family. For each index before the tail, the loop
computes a pointwise polynomial from B and C, stores it to A, then adds that
new A value to the still-old next A value and stores the sum to D:

```text
A[i] = B[i] + C[i] * C[i] + B[i] * B[i] + C[i]
D[i] = A[i] + A[i+1]
```

The loop advances in ascending order, so `A[i+1]` is the caller's original
value at the time D[i] is computed. The last A and D values are untouched.
This kernel is distinct from s241's cross-coupled product map, s243's ordered
A/B lookahead updates, and s244's next-position write and transient-store
trace. It is also distinct from s131's direct forward substitution: s1244
first applies a quadratic pointwise transform and writes a separate neighbor
sum array.

## Contract

The exported symbol is `tsvc_s1244_polynomial_neighbor_sum`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, A[n], B[n], C[n], D[n]]`, with `n` in `2..32`.
- Every input value is in `[-2,2]`. All intermediate values are exact small
  integers in both the source's binary64 profile and signed i64.
- Perform one ascending sweep over `i=0..n-2`, preserving source statement
  order. Leave `A[n-1]` and `D[n-1]` unchanged.
- Emit final A followed by final D as little-endian signed i64 values and
  return `2*n`. Required output capacity is `16*n` bytes.
- Malformed input returns `-1`; null output or insufficient capacity returns
  `-2` without writes. Input is unchanged.

The upstream timing loop repeats the kernel and updates its state between
passes. This profile represents one loop-body sweep over explicit bounded
arrays, omitting timing, initialization, and checksum wrappers.

## Source and rights

The behavior reference is `s1244` at lines 2263–2285 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2263),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`TSVC/NodeSplitting-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/NodeSplitting-dbl/tsc.c).
TSVC comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s1244_polynomial_neighbor_sum_oracle.py`](../../tsvc_s1244_polynomial_neighbor_sum_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s1244_polynomial_neighbor_sum.c`](../../../c/t/tsvc_s1244_polynomial_neighbor_sum.c) |
| C3 | [`tsvc_s1244_polynomial_neighbor_sum.c3`](../../../c3/t/tsvc_s1244_polynomial_neighbor_sum.c3) |
| C++ | [`tsvc_s1244_polynomial_neighbor_sum.cpp`](../../../cpp/t/tsvc_s1244_polynomial_neighbor_sum.cpp) |
| Elisa | [`tsvc_s1244_polynomial_neighbor_sum.elisa`](../../../elisa/t/tsvc_s1244_polynomial_neighbor_sum.elisa) |
| Nim | [`tsvc_s1244_polynomial_neighbor_sum.nim`](../../../nim/t/tsvc_s1244_polynomial_neighbor_sum.nim) |
| Odin | [`tsvc_s1244_polynomial_neighbor_sum.odin`](../../../odin/t/tsvc_s1244_polynomial_neighbor_sum.odin) |
| Rust | [`tsvc_s1244_polynomial_neighbor_sum.rs`](../../../rust/t/tsvc_s1244_polynomial_neighbor_sum.rs) |
| V | [`tsvc_s1244_polynomial_neighbor_sum.v`](../../../v/t/tsvc_s1244_polynomial_neighbor_sum.v) |
| Zig | [`tsvc_s1244_polynomial_neighbor_sum.zig`](../../../zig/t/tsvc_s1244_polynomial_neighbor_sum.zig) |
