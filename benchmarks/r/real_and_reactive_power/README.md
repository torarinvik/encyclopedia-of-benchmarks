# Real and Reactive Power

This package benchmarks both functions in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/real_and_reactive_power.py): real power is `apparent_power * power_factor`, and reactive power is `apparent_power * sqrt(1 - power_factor**2)`. The operation selector chooses which function to measure: `0` for real power and `1` for reactive power.

The `i64_array_float64` ABI accepts exactly `[operation, apparent_power, factor_basis_points]`. Apparent power is an integer in `[-1,000,000,000, 1,000,000,000]`. The power factor is an integer in `[-10,000, 10,000]`, decoded as `factor_basis_points / 10,000.0`; this defines a bounded, four-decimal input grid for the source's floating-point factor. Negative apparent power is preserved by both formulas. A negative power factor changes real power's sign but does not by itself change reactive power's sign. Zero apparent power returns zero for either operation.

The pinned functions reject power factors outside `[-1,1]`; malformed ABI values and unsupported selectors return `-1e300`. The selected bounds keep all results finite. Reactive power preserves the source's operation sequence: square the factor, subtract from one, take the square root, then multiply by apparent power. The nearby `electrical_impedance` and `power_factor_correction` benchmarks cover different circuit calculations and do not implement either formula here.

Runtime and auxiliary space are O(1). The workload includes both operations, the source examples, signed values, endpoint factors, zero, and invalid inputs.

The shared float64 runner validates both branches with the source operation order and the workload's `1e-12` tolerances.
