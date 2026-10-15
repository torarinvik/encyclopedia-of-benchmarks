# Net present value

Calculate the net present value of a cash-flow sequence at one discount rate. Period zero is undiscounted; each later cash flow is divided by `(1 + rate)^period` and the terms are added in order.

## Contract

- Input is packed as `[n, rate_basis_points, cash_flow_0, ...]` in signed 64-bit integers, with exact packing and no trailing values.
- `n` is in `0..=64`; each cash flow is in `[-1,000,000, 1,000,000]`; the rate is 0 through 1,000 basis points (0% through 10%).
- Convert the integer rate with `rate = rate_basis_points / 10,000.0`. Compute each term as `cash_flow[t] / pow(1.0 + rate, t)`, then add terms sequentially from 0.0.
- Return one binary64 result. The empty sequence returns 0.0. Invalid packing or values return `-1e300`.
- Workload comparisons use absolute and relative tolerance `1e-12`.

Integer cash flows are a bounded portable subset of the pinned binary64 API. The rate basis-point encoding makes the input discrete and unambiguous. The chosen bounds keep all terms finite and the accumulated result far below binary64 overflow. Ports preserve the source's zero-based period exponent and source-ordered term sum; standard library power implementations may differ in the final few bits.

The shared float64 runner checks each workload result using the declared `1e-12` absolute and relative tolerances.

## Source and distinction

- [TheAlgorithms/Rust `npv.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/npv.rs)

This package evaluates one rate and returns one scalar. The separate [`npv_sensitivity` candidate](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/npv_sensitivity.rs) evaluates a vector of rates and returns one NPV per rate. There is no existing NPV package in this benchmark tree.
