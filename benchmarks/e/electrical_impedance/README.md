# Electrical impedance

Solve impedance, resistance, or reactance from the other two values using the pinned AC impedance relation.

## Contract

- The `i64_array_float64` ABI accepts `[resistance, reactance, impedance]` and returns the solved value as binary64, in ohms.
- Exactly one value must be zero. Each value must be an integer from 0 through 1,000.
- When solving resistance or reactance, impedance must be at least as large as the other known component so the square-root radicand is nonnegative.
- Invalid length, range, zero count, or negative radicand returns `-1e300`. Valid results use relative and absolute tolerance `1e-12`.

## Source semantics

This follows the pinned [TheAlgorithms Python `electrical_impedance.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/electrical_impedance.py), which requires exactly one zero and uses `sqrt(Z² - X²)`, `sqrt(Z² - R²)`, or `sqrt(R² + X²)` for the missing value. The bounded nonnegative integer domain is a normalized subset of the source's numeric inputs. The source raises for invalid zero counts and negative radicands; this benchmark encodes those cases with the invalid sentinel.

## Workload

[`workload.json`](workload.json) covers all three solved values, exact and irrational results, zero radicands, invalid input shapes, and impossible component combinations.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/electrical_impedance.c`](../../../c/e/electrical_impedance.c) |
| C3 | [`c3/e/electrical_impedance.c3`](../../../c3/e/electrical_impedance.c3) |
| C++ | [`cpp/e/electrical_impedance.cpp`](../../../cpp/e/electrical_impedance.cpp) |
| Elisa | [`elisa/e/electrical_impedance.elisa`](../../../elisa/e/electrical_impedance.elisa) |
| Nim | [`nim/e/electrical_impedance.nim`](../../../nim/e/electrical_impedance.nim) |
| Odin | [`odin/e/electrical_impedance.odin`](../../../odin/e/electrical_impedance.odin) |
| Rust | [`rust/e/electrical_impedance.rs`](../../../rust/e/electrical_impedance.rs) |
| V | [`v/e/electrical_impedance.v`](../../../v/e/electrical_impedance.v) |
| Zig | [`zig/e/electrical_impedance.zig`](../../../zig/e/electrical_impedance.zig) |

The package uses the `i64_array_float64` benchmark ABI.
