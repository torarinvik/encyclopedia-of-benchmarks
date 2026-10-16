# Power factor correction

Calculate the shunt capacitance or shunt inductance needed to move a load from its current power factor to a target power factor, following the pinned [TheAlgorithms Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/power_factor_correction.py).

## Contract

- The `i64_array_float64` ABI accepts `[operation, voltage, frequency, real_power, current_pf_basis_points, expected_pf_basis_points]` and returns binary64.
- Operation `0` returns shunt capacitance in farads: `delta_q / (2*pi*frequency*voltage^2)`. Operation `1` returns shunt inductance in henries: `voltage^2 / (2*pi*frequency*delta_q)`.
- The source computes each reactive power as `(real_power / power_factor) * sin(acos(power_factor))`, then subtracts expected reactive power from current reactive power. Ports preserve that expression order.
- Voltage and frequency are integers from 1 through 1,000; real power is from -1,000,000 through 1,000,000 watts. Power factors are nonzero integer basis points from -10,000 through 10,000, decoded by dividing by 10,000.
- Zero power factors are invalid because the source divides by the factor. Equal factors and zero real power are invalid in inductor mode because the source rejects zero reactive-power difference. Equal factors remain valid in capacitor mode and yield zero capacitance.
- Invalid values, operation, or length return `-1e300`. Valid outputs use relative and absolute tolerances of `1e-12`.

The workload includes both source examples, negative factors and real power, unity factors, equal-factor capacitor mode, and invalid edge cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/power_factor_correction.c`](../../../c/p/power_factor_correction.c) |
| C3 | [`c3/p/power_factor_correction.c3`](../../../c3/p/power_factor_correction.c3) |
| C++ | [`cpp/p/power_factor_correction.cpp`](../../../cpp/p/power_factor_correction.cpp) |
| Elisa | [`elisa/p/power_factor_correction.elisa`](../../../elisa/p/power_factor_correction.elisa) |
| Nim | [`nim/p/power_factor_correction.nim`](../../../nim/p/power_factor_correction.nim) |
| Odin | [`odin/p/power_factor_correction.odin`](../../../odin/p/power_factor_correction.odin) |
| Rust | [`rust/p/power_factor_correction.rs`](../../../rust/p/power_factor_correction.rs) |
| V | [`v/p/power_factor_correction.v`](../../../v/p/power_factor_correction.v) |
| Zig | [`zig/p/power_factor_correction.zig`](../../../zig/p/power_factor_correction.zig) |
