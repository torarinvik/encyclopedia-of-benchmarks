# TSVC s241 cross-coupled product map

This package is a bounded, clean-room, one-sweep profile of TSVC `s241` from
the `NodeSplitting-dbl` family. The kernel updates two arrays in ascending
index order:

```text
for i from 0 to n-2:
    A[i] = B[i] * C[i] * D[i]
    B[i] = A[i] * A[i+1] * D[i]
```

The second assignment observes the newly written `A[i]` and the still-old
`A[i+1]`; it then updates `B[i]` after using its old value for the first
assignment. The final entries `A[n-1]` and `B[n-1]` are untouched. This is a
coupled, adjacent-value product map; it differs from the existing one-array
neighbor recurrences and from pointwise multi-array maps without the ordered
cross-array dependency.

## Contract

The exported symbol is `tsvc_s241_cross_coupled_product_map`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, A[n], B[n], C[n], D[n]]`, with `n` in `2..64`.
- Every input value is in `[-2,2]`. Products remain small integers exactly
  representable by the source's binary64 `TYPE` profile.
- Perform one ascending sweep over indices `0..n-2`, preserving the statement
  order above. Leave the final A and B slots unchanged.
- Emit final A followed by final B as little-endian signed i64 values and
  return `2*n`. Required output capacity is `16*n` bytes.
- Malformed input returns `-1`; null output or insufficient capacity returns
  `-2` without writes. Input is unchanged.

The upstream code repeats this loop for timing, and successive passes mutate
its state. This bounded package profiles one source loop-body pass with
explicit caller input and observable final arrays, rather than that repeated
timing state trajectory. The source initializes A, B, C, and D to one; the
workload varies them to expose both update equations and the untouched tail.

## Source and rights

The behavior reference is `s241` at lines 2156–2179 in
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2156),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its initialization is at lines
410–414. The launcher is
[`TSVC/NodeSplitting-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/NodeSplitting-dbl/tsc.c),
which selects `TYPE double` and the node-splitting family. TSVC comments
attribute its non-four-digit codelets to David Callahan, Jack Dongarra, and
David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s241_cross_coupled_product_map_oracle.py`](../../tsvc_s241_cross_coupled_product_map_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s241_cross_coupled_product_map.c`](../../../c/t/tsvc_s241_cross_coupled_product_map.c) |
| C3 | [`tsvc_s241_cross_coupled_product_map.c3`](../../../c3/t/tsvc_s241_cross_coupled_product_map.c3) |
| C++ | [`tsvc_s241_cross_coupled_product_map.cpp`](../../../cpp/t/tsvc_s241_cross_coupled_product_map.cpp) |
| Elisa | [`tsvc_s241_cross_coupled_product_map.elisa`](../../../elisa/t/tsvc_s241_cross_coupled_product_map.elisa) |
| Nim | [`tsvc_s241_cross_coupled_product_map.nim`](../../../nim/t/tsvc_s241_cross_coupled_product_map.nim) |
| Odin | [`tsvc_s241_cross_coupled_product_map.odin`](../../../odin/t/tsvc_s241_cross_coupled_product_map.odin) |
| Rust | [`tsvc_s241_cross_coupled_product_map.rs`](../../../rust/t/tsvc_s241_cross_coupled_product_map.rs) |
| V | [`tsvc_s241_cross_coupled_product_map.v`](../../../v/t/tsvc_s241_cross_coupled_product_map.v) |
| Zig | [`tsvc_s241_cross_coupled_product_map.zig`](../../../zig/t/tsvc_s241_cross_coupled_product_map.zig) |
