# TSVC ControlLoops vtv elementwise product

This package profiles the TSVC `vtv` kernel: on every pass, it multiplies each
element of A in place by the corresponding element of B. The update is
elementwise; it is not the scalar array-product reduction in s312 or the
three-factor map in `vtvtv`.

## Contract

- Export `tsvc_vtv_elementwise_product` with the `i64_array_bytes_output` ABI.
- Input is `[n,passes,A[n],B[n]]`, with `1<=n<=32`, `1<=passes<=8`, exact
  length `2+2*n`, and values in `[-2,2]`.
- For each pass and ascending index, compute `A[i] = A[i] * B[i]`.
- Output is final A encoded as little-endian signed i64; success returns
  `8*n` bytes. Invalid/null input returns `-1`; null output or insufficient
  capacity returns `-2` without writes.
- The source launcher selects `TYPE double` or `TYPE float`. This bounded
  integer profile keeps values exact in both formats and bounds repeated
  products to `[-512,512]`.

## Provenance and rights

Pinned source: `lac-dcc/Benchmarks`, commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`, `TSVC/tsc.inc`, `vtv` lines
5302–5328, selected by `ControlLoops-dbl` and `ControlLoops-flt`. No explicit
modification or redistribution grant was found in the reviewed source; these
are clean-room ports. See [LICENSE.txt](LICENSE.txt).

Independent oracle: [`benchmarks/tsvc_vtv_elementwise_product_oracle.py`](../../tsvc_vtv_elementwise_product_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [C](../../../c/t/tsvc_vtv_elementwise_product.c) |
| C3 | [C3](../../../c3/t/tsvc_vtv_elementwise_product.c3) |
| C++ | [C++](../../../cpp/t/tsvc_vtv_elementwise_product.cpp) |
| Elisa | [Elisa](../../../elisa/t/tsvc_vtv_elementwise_product.elisa) |
| Nim | [Nim](../../../nim/t/tsvc_vtv_elementwise_product.nim) |
| Odin | [Odin](../../../odin/t/tsvc_vtv_elementwise_product.odin) |
| Rust | [Rust](../../../rust/t/tsvc_vtv_elementwise_product.rs) |
| V | [V](../../../v/t/tsvc_vtv_elementwise_product.v) |
| Zig | [Zig](../../../zig/t/tsvc_vtv_elementwise_product.zig) |
