# TSVC s312 array product

This package is a bounded clean-room profile of TSVC `s312` from the
`Reductions-dbl` launcher family. It computes the product of every value in
the input array, starting from the multiplicative identity 1:

```text
product = 1
for value in values: product *= value
```

This returns one product over the full input. It differs from
[`get_products_of_all_other_elements`](../../g/get_products_of_all_other_elements/README.md),
which returns one product per position, and from maximum-product-subarray or
fixed-size product algorithms.

## Contract

The exported symbol is `tsvc_s312_array_product`, using the
`i64_array_scalar` ABI:

- Input is `[n, values[n]]`, with `n` in `0..48`.
- Each factor is in `0..2`.
- Multiply factors in input order. The empty product is 1.
- Malformed shape, count, or factors return `-1`.

The largest result is `2^48`, which is exact in the source binary64 profile
and fits signed i64. Restricting factors to nonnegative values keeps the
invalid-input sentinel `-1` disjoint from every valid product.

## Source and rights

The behavior reference is `s312` at lines 3390–3415 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L3390)
in LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is
[`TSVC/Reductions-dbl/tsc.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Reductions-dbl/tsc.c),
which selects `TYPE double` and the reductions family. The source initializes
each factor to `1.000001`; this bounded integer profile accepts caller factors
to expose the product operation while keeping every intermediate exact. The
TSVC source comments attribute its non-four-digit codelets to David Callahan,
Jack Dongarra, and David Levine, *Test Suite for Vectorizing Compilers*.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded loop
contract and reuse no upstream source code or comments; no upstream license or
endorsement is claimed. See [`LICENSE.txt`](LICENSE.txt) for the rights note.

The independent oracle and fixed workload are
[`tsvc_s312_array_product_oracle.py`](../../tsvc_s312_array_product_oracle.py)
and [`workload.json`](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [`tsvc_s312_array_product.c`](../../../c/t/tsvc_s312_array_product.c) |
| C3 | [`tsvc_s312_array_product.c3`](../../../c3/t/tsvc_s312_array_product.c3) |
| C++ | [`tsvc_s312_array_product.cpp`](../../../cpp/t/tsvc_s312_array_product.cpp) |
| Elisa | [`tsvc_s312_array_product.elisa`](../../../elisa/t/tsvc_s312_array_product.elisa) |
| Nim | [`tsvc_s312_array_product.nim`](../../../nim/t/tsvc_s312_array_product.nim) |
| Odin | [`tsvc_s312_array_product.odin`](../../../odin/t/tsvc_s312_array_product.odin) |
| Rust | [`tsvc_s312_array_product.rs`](../../../rust/t/tsvc_s312_array_product.rs) |
| V | [`tsvc_s312_array_product.v`](../../../v/t/tsvc_s312_array_product.v) |
| Zig | [`tsvc_s312_array_product.zig`](../../../zig/t/tsvc_s312_array_product.zig) |
