# TSVC s252 adjacent product pair sum

This package is a bounded, clean-room, one-sweep profile of TSVC `s252` in
the `Expansion-dbl` family. It forms each pointwise product and adds the
previous product to the current one:

```text
s = B[i] * C[i]
A[i] = s + previous_s
previous_s = s
```

The carry starts at zero, so A[0] is just the first product. For later slots,
A[i] is `B[i]*C[i] + B[i-1]*C[i-1]`. This is not a prefix sum: the carry stores
only the immediately preceding product, not the accumulated output. It also
differs from a standard two-tap filter over one array because each tap is a
product from a pair of input arrays.

## Contract

The exported symbol is `tsvc_s252_adjacent_product_pair_sum`, using the
`i64_array_bytes_output` ABI:

- Input is `[n, B[n], C[n]]`, with `n` in `1..64`.
- Every input value is in `[-2,2]`. Products and adjacent sums remain exact
  small integers in binary64 and signed i64.
- Start the scalar carry at zero. Visit indices in ascending order; write
  `A[i]=B[i]*C[i]+carry`, then set `carry=B[i]*C[i]`.
- Emit A as little-endian signed i64 values and return `n`. Required output
  capacity is `8*n` bytes. Inputs are unchanged.
- Malformed input returns `-1`; null output or insufficient capacity returns
  `-2` without writes.

The source initializes A to zero, B/C to one, and resets the scalar carry at
the start of each timing pass. This package accepts bounded caller-provided
B/C arrays and profiles one loop-body pass.

## Source and rights

The behavior reference is `s252` at lines 2424–2448 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L2424),
pinned to LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Initialization is at lines
437–440. The launcher is
[`TSVC/Expansion-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/tsc.c).
TSVC comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s252_adjacent_product_pair_sum_oracle.py`](../../tsvc_s252_adjacent_product_pair_sum_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s252_adjacent_product_pair_sum.c`](../../../c/t/tsvc_s252_adjacent_product_pair_sum.c) |
| C3 | [`tsvc_s252_adjacent_product_pair_sum.c3`](../../../c3/t/tsvc_s252_adjacent_product_pair_sum.c3) |
| C++ | [`tsvc_s252_adjacent_product_pair_sum.cpp`](../../../cpp/t/tsvc_s252_adjacent_product_pair_sum.cpp) |
| Elisa | [`tsvc_s252_adjacent_product_pair_sum.elisa`](../../../elisa/t/tsvc_s252_adjacent_product_pair_sum.elisa) |
| Nim | [`tsvc_s252_adjacent_product_pair_sum.nim`](../../../nim/t/tsvc_s252_adjacent_product_pair_sum.nim) |
| Odin | [`tsvc_s252_adjacent_product_pair_sum.odin`](../../../odin/t/tsvc_s252_adjacent_product_pair_sum.odin) |
| Rust | [`tsvc_s252_adjacent_product_pair_sum.rs`](../../../rust/t/tsvc_s252_adjacent_product_pair_sum.rs) |
| V | [`tsvc_s252_adjacent_product_pair_sum.v`](../../../v/t/tsvc_s252_adjacent_product_pair_sum.v) |
| Zig | [`tsvc_s252_adjacent_product_pair_sum.zig`](../../../zig/t/tsvc_s252_adjacent_product_pair_sum.zig) |
