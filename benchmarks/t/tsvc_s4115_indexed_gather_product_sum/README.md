# TSVC s4115 indexed gather product-sum

This package is a bounded, clean-room profile of TSVC `s4115` from the
`IndirectAddressing-dbl` launcher family. It gathers one B value for each
logical position, multiplies it by the corresponding A value, and accumulates
the products in source order:

```text
sum = 0
for i in 0..n:
    sum += A[i] * B[indexes[i]]
```

This is an indexed gather reduction: indexes may repeat and the gathered
operand comes from B. It is distinct from a dense dot product, the vector
gather-copy, indexed scatter updates, and the s4114/s4117 output-vector gather
maps.

## Contract

The exported symbol is `tsvc_s4115_indexed_gather_product_sum`, using the
`i64_array_scalar` ABI:

- Input is `[n, indexes[n], A[n], B[n]]`, with `n` in 1 through 64.
- Each index is in `[0,n-1]`; duplicate indexes are allowed.
- A and B values are integers in `[0,1,000,000]`.
- Return the ascending-order sum `sum(A[i] * B[indexes[i]])` as a signed i64.
- Malformed input returns `-1`.

The maximum possible result is `64,000,000,000,000`, below both signed i64's
limit and the exact-integer range of the source's binary64 `TYPE`. Nonnegative
operands keep the invalid-input sentinel `-1` disjoint from valid results.
The profile leaves inputs unchanged and excludes TSVC initialization, timing
repetitions, dummy calls, and checker code.

## Source and rights

The behavior reference is `s4115` in `TSVC/tsc.inc`, lines 4787–4813; the
reduction loop is at lines 4799–4805. It is pinned to LAC-DCC `Benchmarks`
commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L4787). The launcher
[`TSVC/IndirectAddressing-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/IndirectAddressing-dbl/tsc.c)
selects `TYPE double` and `INDIRECT_ADDRESSING`. TSVC comments attribute its
non-four-digit codelets to David Callahan, Jack Dongarra, and David Levine,
*Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. The ports independently implement the bounded reduction
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [`LICENSE.txt`](LICENSE.txt).

The independent oracle and fixed workload are
[`tsvc_s4115_indexed_gather_product_sum_oracle.py`](../../tsvc_s4115_indexed_gather_product_sum_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s4115_indexed_gather_product_sum.c`](../../../c/t/tsvc_s4115_indexed_gather_product_sum.c) |
| C3 | [`tsvc_s4115_indexed_gather_product_sum.c3`](../../../c3/t/tsvc_s4115_indexed_gather_product_sum.c3) |
| C++ | [`tsvc_s4115_indexed_gather_product_sum.cpp`](../../../cpp/t/tsvc_s4115_indexed_gather_product_sum.cpp) |
| Elisa | [`tsvc_s4115_indexed_gather_product_sum.elisa`](../../../elisa/t/tsvc_s4115_indexed_gather_product_sum.elisa) |
| Nim | [`tsvc_s4115_indexed_gather_product_sum.nim`](../../../nim/t/tsvc_s4115_indexed_gather_product_sum.nim) |
| Odin | [`tsvc_s4115_indexed_gather_product_sum.odin`](../../../odin/t/tsvc_s4115_indexed_gather_product_sum.odin) |
| Rust | [`tsvc_s4115_indexed_gather_product_sum.rs`](../../../rust/t/tsvc_s4115_indexed_gather_product_sum.rs) |
| V | [`tsvc_s4115_indexed_gather_product_sum.v`](../../../v/t/tsvc_s4115_indexed_gather_product_sum.v) |
| Zig | [`tsvc_s4115_indexed_gather_product_sum.zig`](../../../zig/t/tsvc_s4115_indexed_gather_product_sum.zig) |
