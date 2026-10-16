# Earnings Per Sale

This package ports `earnings_per_sale` from the pinned Rust `finance_ratios.rs` module. The formula is `(net_income - preferred_dividend) / average_shares`; operands are signed integer values represented as binary64 inputs to the calculation.

## Contract

The `i64_array_float64` input is exactly 3 values in this order: net_income, preferred_dividend, average_shares. Domain: net_income in [-1,000,000, 1,000,000], preferred_dividend in [0, 1,000,000], average_shares in [1, 1,000,000]. Invalid lengths or values return `-1e300`. The source formula is evaluated using binary64 arithmetic; the workload uses absolute and relative tolerances of `1e-12`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/earnings_per_sale.c`](../../../c/e/earnings_per_sale.c) |
| C3 | [`c3/e/earnings_per_sale.c3`](../../../c3/e/earnings_per_sale.c3) |
| C++ | [`cpp/e/earnings_per_sale.cpp`](../../../cpp/e/earnings_per_sale.cpp) |
| Elisa | [`elisa/e/earnings_per_sale.elisa`](../../../elisa/e/earnings_per_sale.elisa) |
| Nim | [`nim/e/earnings_per_sale.nim`](../../../nim/e/earnings_per_sale.nim) |
| Odin | [`odin/e/earnings_per_sale.odin`](../../../odin/e/earnings_per_sale.odin) |
| Rust | [`rust/e/earnings_per_sale.rs`](../../../rust/e/earnings_per_sale.rs) |
| V | [`v/e/earnings_per_sale.v`](../../../v/e/earnings_per_sale.v) |
| Zig | [`zig/e/earnings_per_sale.zig`](../../../zig/e/earnings_per_sale.zig) |

## Pinned source

[TheAlgorithms/Rust `finance_ratios.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/finance_ratios.rs)

See [`workload.json`](workload.json) for source examples, boundary inputs, and invalid-domain cases.
