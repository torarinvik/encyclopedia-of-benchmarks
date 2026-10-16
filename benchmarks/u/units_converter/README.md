# Units converter

This benchmark ports the pinned Java `UnitsConverter`. Given directed affine conversions, it adds their inverses, composes compatible pairs, and repeats that process until no new ordered unit pairs appear. A conversion applies `slope * value + intercept`.

## Contract

The `i64_array_float64` input has two profiles:

- Temperature profile: `[0, from_unit, to_unit, value_micro]`. Unit IDs are `0=Kelvin`, `1=Celsius`, `2=Fahrenheit`, `3=Réaumur`, `4=Delisle`, and `5=Rankine`. This profile uses the five directed conversions from the pinned `UnitConversions.TEMPERATURE` configuration and computes the same inverse/composition closure as `UnitsConverter`.
- Custom profile: `[1, unit_count, edge_count, from_unit, to_unit, value_micro, from0, to0, slope0_ppm, intercept0_micro, ...]`. Each edge represents `to_value = (slope_ppm / 1,000,000) * from_value + (intercept_micro / 1,000,000)`.

For the custom profile, `unit_count` is 2 through 8, `edge_count` is 0 through `unit_count - 1`, and the undirected edges must form a forest. Edge endpoints are distinct unit IDs in `[0, unit_count)`. Each slope is nonzero and in `[-5,000,000, 5,000,000]` parts per million; each intercept is in `[-1,000,000,000,000, 1,000,000,000,000]` micro-units. Both profiles bound `value_micro` to the same range, representing input values from -1,000,000 through 1,000,000. A valid query names distinct in-range units connected by the graph. Missing pairs and same-unit requests map the source exceptions to `-1e300`.

Restricting the custom graph to a forest gives each connected pair a unique route, avoiding conflicting affine paths while keeping the source's iterative inverse/composition closure deterministic. The conversion list preserves input edge order and uses first-inserted pair semantics. The fixed temperature profile is a configuration of this same algorithm, so the sibling `UnitConversions.java` candidate maps to profile 0 rather than a separate benchmark identity. `temperature_converter` remains separate: its pinned class exposes six direct Celsius/Fahrenheit/Kelvin formulas, while this package exercises the six-unit graph closure.

The packed array is at most 35 values so one extra value can be represented as malformed input; the largest valid custom graph uses 34 values. The binary64 result preserves the composed affine expression without rounding. Invalid input, disconnected unit pairs, and same-unit requests return `-1e300`.

## Pinned sources

- [`UnitsConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/UnitsConverter.java) defines inversion, composition, closure, and conversion.
- [`UnitConversions.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/UnitConversions.java) supplies the fixed temperature graph.
- [`AffineConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/AffineConverter.java) defines the affine operations used by the closure.

All three sources are pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. [`workload.json`](workload.json) covers the temperature profile, custom chains and branches, inversions, maximum graph size, missing pairs, same-unit inputs, and malformed graphs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/u/units_converter.c`](../../../c/u/units_converter.c) |
| C3 | [`c3/u/units_converter.c3`](../../../c3/u/units_converter.c3) |
| C++ | [`cpp/u/units_converter.cpp`](../../../cpp/u/units_converter.cpp) |
| Elisa | [`elisa/u/units_converter.elisa`](../../../elisa/u/units_converter.elisa) |
| Nim | [`nim/u/units_converter.nim`](../../../nim/u/units_converter.nim) |
| Odin | [`odin/u/units_converter.odin`](../../../odin/u/units_converter.odin) |
| Rust | [`rust/u/units_converter.rs`](../../../rust/u/units_converter.rs) |
| V | [`v/u/units_converter.v`](../../../v/u/units_converter.v) |
| Zig | [`zig/u/units_converter.zig`](../../../zig/u/units_converter.zig) |
