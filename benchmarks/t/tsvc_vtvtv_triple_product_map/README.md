# TSVC `vtvtv` triple-product map

This clean-room profile implements the ControlLoops `vtvtv` loop from the
pinned TSVC source. In ascending order it replaces each `A[i]` with the
left-associative product `(A[i] * B[i]) * C[i]`. Each index is independent;
the source's repeated timing loop and dummy call are excluded.

The codelet is distinct from s152's in-place three-factor accumulation
(`A += D*E*C`) and s241's coupled two-array update. It does not measure a
general matrix or convolution operation.

## Contract

The exported function is `tsvc_vtvtv_triple_product_map` using the
`float64_slice_io` ABI.

- Input: `[n, A[n], B[n], C[n]]`, with `1 <= n <= 64`.
- Values are finite integer-valued binary64 numbers in `[-2,2]`; all products
  are exactly represented in binary32 and binary64.
- Perform one ascending pass of `A[i] = (A[i] * B[i]) * C[i]` and emit the
  complete resulting A vector. Input is unchanged.
- Malformed input returns `-1`; null output or capacity below n returns `-2`
  after input validation, without writes.

## Source and rights

Source: `vtvtv` at lines 5411–5434 of
[`TSVC/tsc.inc`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L5411),
from LAC-DCC `Benchmarks` commit
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The launcher is
[`TSVC/ControlLoops-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlLoops-dbl/info.sh);
the corresponding float launcher selects the same operation with binary32
`TYPE`. No explicit redistribution grant was found in the reviewed materials.
Ports are independently written and include no copied upstream source text.
See [LICENSE.txt](LICENSE.txt).

Fixtures are in [workload.json](workload.json); the independent oracle is
[`tsvc_vtvtv_triple_product_map_oracle.py`](../../tsvc_vtvtv_triple_product_map_oracle.py).

## Ports

| Language | File |
|---|---|
| C | [tsvc_vtvtv_triple_product_map.c](../../../c/t/tsvc_vtvtv_triple_product_map.c) |
| C3 | [tsvc_vtvtv_triple_product_map.c3](../../../c3/t/tsvc_vtvtv_triple_product_map.c3) |
| C++ | [tsvc_vtvtv_triple_product_map.cpp](../../../cpp/t/tsvc_vtvtv_triple_product_map.cpp) |
| Elisa | [tsvc_vtvtv_triple_product_map.elisa](../../../elisa/t/tsvc_vtvtv_triple_product_map.elisa) |
| Nim | [tsvc_vtvtv_triple_product_map.nim](../../../nim/t/tsvc_vtvtv_triple_product_map.nim) |
| Odin | [tsvc_vtvtv_triple_product_map.odin](../../../odin/t/tsvc_vtvtv_triple_product_map.odin) |
| Rust | [tsvc_vtvtv_triple_product_map.rs](../../../rust/t/tsvc_vtvtv_triple_product_map.rs) |
| V | [tsvc_vtvtv_triple_product_map.v](../../../v/t/tsvc_vtvtv_triple_product_map.v) |
| Zig | [tsvc_vtvtv_triple_product_map.zig](../../../zig/t/tsvc_vtvtv_triple_product_map.zig) |
