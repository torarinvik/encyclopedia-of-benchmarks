# Net present value sensitivity

Evaluate one cash-flow sequence at several discount rates, returning an NPV for each rate in input order.

## Contract

- Input is packed as `[n, rate_count, cashflows..., rate_basis_points...]` in signed 64-bit integers, with exact packing and no trailing values.
- `n` is in `0..=64`, `rate_count` is in `0..=32`, cash flows are in `[-1,000,000, 1,000,000]`, and each rate is 0 through 1,000 basis points (0% through 10%).
- Normalize each rate as `rate = rate_basis_points / 10,000.0`. For each rate, calculate `cash_flow[t] / (1.0 + rate).powi(t)` beginning at period zero, and sum terms sequentially from 0.0.
- Emit one IEEE-754 binary64 little-endian value per rate, in rate order. Return `8 * rate_count` bytes (at most 256); no rates returns zero bytes. With no cash flows, each supplied rate returns 0.0.
- Malformed packing or out-of-domain values return `-1`; insufficient output capacity returns `-2`.
- Comparisons use `1e-12` absolute and relative tolerance.

Integer cash flows and basis-point rates define a bounded discrete subset of the pinned f64 API. All terms are finite under these bounds. Ports preserve the source's per-rate term order; integer-power and general-purpose power functions may differ in their final low bits, so vector comparisons use the declared tolerance.

## Source and distinction

- [TheAlgorithms/Rust `npv_sensitivity.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/npv_sensitivity.rs)

This returns a vector for multiple discount rates. The separate [`npv`](../npv/README.md) package accepts one rate and returns one binary64 scalar.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/npv_sensitivity.c`](../../../c/n/npv_sensitivity.c) |
| C3 | [`c3/n/npv_sensitivity.c3`](../../../c3/n/npv_sensitivity.c3) |
| C++ | [`cpp/n/npv_sensitivity.cpp`](../../../cpp/n/npv_sensitivity.cpp) |
| Elisa | [`elisa/n/npv_sensitivity.elisa`](../../../elisa/n/npv_sensitivity.elisa) |
| Nim | [`nim/n/npv_sensitivity.nim`](../../../nim/n/npv_sensitivity.nim) |
| Odin | [`odin/n/npv_sensitivity.odin`](../../../odin/n/npv_sensitivity.odin) |
| Rust | [`rust/n/npv_sensitivity.rs`](../../../rust/n/npv_sensitivity.rs) |
| V | [`v/n/npv_sensitivity.v`](../../../v/n/npv_sensitivity.v) |
| Zig | [`zig/n/npv_sensitivity.zig`](../../../zig/n/npv_sensitivity.zig) |
