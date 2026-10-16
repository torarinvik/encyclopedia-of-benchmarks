# Gross Profit Margin

This package ports `gross_profit_margin` from the pinned Rust `finance_ratios.rs` module. The formula is `(revenue - cost) / revenue`; operands are signed integer values represented as binary64 inputs to the calculation.

## Contract

The `i64_array_float64` input is exactly 2 values in this order: revenue, cost. Domain: revenue in [1, 1,000,000], cost in [0, 1,000,000]. Invalid lengths or values return `-1e300`. The source formula is evaluated using binary64 arithmetic; the workload uses absolute and relative tolerances of `1e-12`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gross_profit_margin.c`](../../../c/g/gross_profit_margin.c) |
| C3 | [`c3/g/gross_profit_margin.c3`](../../../c3/g/gross_profit_margin.c3) |
| C++ | [`cpp/g/gross_profit_margin.cpp`](../../../cpp/g/gross_profit_margin.cpp) |
| Elisa | [`elisa/g/gross_profit_margin.elisa`](../../../elisa/g/gross_profit_margin.elisa) |
| Nim | [`nim/g/gross_profit_margin.nim`](../../../nim/g/gross_profit_margin.nim) |
| Odin | [`odin/g/gross_profit_margin.odin`](../../../odin/g/gross_profit_margin.odin) |
| Rust | [`rust/g/gross_profit_margin.rs`](../../../rust/g/gross_profit_margin.rs) |
| V | [`v/g/gross_profit_margin.v`](../../../v/g/gross_profit_margin.v) |
| Zig | [`zig/g/gross_profit_margin.zig`](../../../zig/g/gross_profit_margin.zig) |

## Pinned source

[TheAlgorithms/Rust `finance_ratios.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/finance_ratios.rs)

See [`workload.json`](workload.json) for source examples, boundary inputs, and invalid-domain cases.
