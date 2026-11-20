# Top Trading Cycles for housing exchange

Each agent initially owns the correspondingly numbered house and reports a
strict ranking of all houses. In every round, each remaining agent points to
their favorite remaining house and each remaining house points to its owner.
Every directed cycle trades its houses, after which those agents and houses
leave the market. The process ends with a complete allocation.

This is the Gale Top Trading Cycles rule for the strict Shapley–Scarf housing
market. It differs from local [stable marriage](../../s/stable_matching/README.md)
and [stable roommates](../../s/stable_roommates/README.md), which pair agents
under mutual preference constraints rather than trade initially owned houses.
The 2016 [Stable Partition Problem chapter](https://doi.org/10.1007/978-1-4939-2864-4_397)
mentions TTC for strict B-preferences; the benchmark follows the standard
housing-market formulation in Shapley and Scarf's [1974 paper](https://doi.org/10.1016/0304-4068(74)90033-0).

## Contract

Input is `[n, row_0, ..., row_(n-1)]`, where `1<=n<=8` and each row is a
permutation of house IDs `0..n-1`, ordered from most to least preferred. Agent
`i` initially owns house `i`. The valid input length is `1+n*n`; a trailing
word is invalid. The maximum parseable length is 66.

The scalar result packs each agent's assigned house in a fixed three-bit field:
`1 + Σ(allocation[i] << (3*i))`. The offset keeps the valid result nonnegative
even for the one-agent market. Invalid input returns `-1`. No floating-point
arithmetic or external workspace is used.

The primary reference discovers all cycles in each round by functional-graph
path coloring. The independent reference removes one cycle at a time using
Floyd cycle detection and checks the resulting allocation against the direct
no-blocking-coalition definition of the housing-market core.

| Language | Port |
|---|---|
| C | [c/h/housing_top_trading_cycles.c](../../../c/h/housing_top_trading_cycles.c) |
| C3 | [c3/h/housing_top_trading_cycles.c3](../../../c3/h/housing_top_trading_cycles.c3) |
| C++ | [cpp/h/housing_top_trading_cycles.cpp](../../../cpp/h/housing_top_trading_cycles.cpp) |
| Elisa | [elisa/h/housing_top_trading_cycles.elisa](../../../elisa/h/housing_top_trading_cycles.elisa) |
| Mojo | [mojo/h/housing_top_trading_cycles.mojo](../../../mojo/h/housing_top_trading_cycles.mojo) |
| Nim | [nim/h/housing_top_trading_cycles.nim](../../../nim/h/housing_top_trading_cycles.nim) |
| Odin | [odin/h/housing_top_trading_cycles.odin](../../../odin/h/housing_top_trading_cycles.odin) |
| Rust | [rust/h/housing_top_trading_cycles.rs](../../../rust/h/housing_top_trading_cycles.rs) |
| V | [v/h/housing_top_trading_cycles.v](../../../v/h/housing_top_trading_cycles.v) |
| Zig | [zig/h/housing_top_trading_cycles.zig](../../../zig/h/housing_top_trading_cycles.zig) |
