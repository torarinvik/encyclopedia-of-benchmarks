# Debt To Equity

This package ports `debt_to_equity` from the pinned Rust `finance_ratios.rs` module. The formula is `debt / equity`; operands are signed integer values represented as binary64 inputs to the calculation.

## Contract

The `i64_array_float64` input is exactly 2 values in this order: debt, equity. Domain: debt in [0, 1,000,000], equity in [1, 1,000,000]. Invalid lengths or values return `-1e300`. The source formula is evaluated using binary64 arithmetic; the workload uses absolute and relative tolerances of `1e-12`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/debt_to_equity.c`](../../../c/d/debt_to_equity.c) |
| C3 | [`c3/d/debt_to_equity.c3`](../../../c3/d/debt_to_equity.c3) |
| C++ | [`cpp/d/debt_to_equity.cpp`](../../../cpp/d/debt_to_equity.cpp) |
| Elisa | [`elisa/d/debt_to_equity.elisa`](../../../elisa/d/debt_to_equity.elisa) |
| Nim | [`nim/d/debt_to_equity.nim`](../../../nim/d/debt_to_equity.nim) |
| Odin | [`odin/d/debt_to_equity.odin`](../../../odin/d/debt_to_equity.odin) |
| Rust | [`rust/d/debt_to_equity.rs`](../../../rust/d/debt_to_equity.rs) |
| V | [`v/d/debt_to_equity.v`](../../../v/d/debt_to_equity.v) |
| Zig | [`zig/d/debt_to_equity.zig`](../../../zig/d/debt_to_equity.zig) |

## Pinned source

[TheAlgorithms/Rust `finance_ratios.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/finance_ratios.rs)

See [`workload.json`](workload.json) for source examples, boundary inputs, and invalid-domain cases.
