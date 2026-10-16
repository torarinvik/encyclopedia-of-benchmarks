# Return On Investment

This package ports `return_on_investment` from the pinned Rust `finance_ratios.rs` module. The formula is `(gain - cost) / cost`; operands are signed integer values represented as binary64 inputs to the calculation.

## Contract

The `i64_array_float64` input is exactly 2 values in this order: gain, cost. Domain: gain in [-1,000,000, 1,000,000], cost in [1, 1,000,000]. Invalid lengths or values return `-1e300`. The source formula is evaluated using binary64 arithmetic; the workload uses absolute and relative tolerances of `1e-12`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/return_on_investment.c`](../../../c/r/return_on_investment.c) |
| C3 | [`c3/r/return_on_investment.c3`](../../../c3/r/return_on_investment.c3) |
| C++ | [`cpp/r/return_on_investment.cpp`](../../../cpp/r/return_on_investment.cpp) |
| Elisa | [`elisa/r/return_on_investment.elisa`](../../../elisa/r/return_on_investment.elisa) |
| Nim | [`nim/r/return_on_investment.nim`](../../../nim/r/return_on_investment.nim) |
| Odin | [`odin/r/return_on_investment.odin`](../../../odin/r/return_on_investment.odin) |
| Rust | [`rust/r/return_on_investment.rs`](../../../rust/r/return_on_investment.rs) |
| V | [`v/r/return_on_investment.v`](../../../v/r/return_on_investment.v) |
| Zig | [`zig/r/return_on_investment.zig`](../../../zig/r/return_on_investment.zig) |

## Pinned source

[TheAlgorithms/Rust `finance_ratios.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/finance_ratios.rs)

See [`workload.json`](workload.json) for source examples, boundary inputs, and invalid-domain cases.
