# Apparent power

The pinned Python function converts voltage and current phasors from polar form to rectangular form, multiplies the two complex values, and returns the complex apparent power. This package records each component as a separate scalar case through the existing `i64_array_float64` ABI.

## Contract

- The input array is `[component_selector, voltage, current, voltage_angle_degrees, current_angle_degrees]`. Selector `0` returns the real component; selector `1` returns the imaginary component.
- Voltage and current are integer-valued magnitudes from 0 through 1,000; each angle is an integer number of degrees from -360 through 360. This bounded discrete domain is a portable subset of the source's floating-point parameters.
- The calculation preserves the source's phasor multiplication: `rect(V, radians(a)) * rect(I, radians(b))`. Its real and imaginary components are computed from the corresponding rectangular coordinates.
- Invalid lengths, selectors, magnitudes, or angles return `-1e300`. Valid components use absolute tolerance `1e-9` and relative tolerance `1e-12`.

## Workload

[`workload.json`](workload.json) includes both output components for the pinned examples, zero magnitude, and nontrivial phase combinations, plus invalid-input sentinels. Every case is one timed scalar result.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/apparent_power.c`](../../../c/a/apparent_power.c) |
| C3 | [`c3/a/apparent_power.c3`](../../../c3/a/apparent_power.c3) |
| C++ | [`cpp/a/apparent_power.cpp`](../../../cpp/a/apparent_power.cpp) |
| Elisa | [`elisa/a/apparent_power.elisa`](../../../elisa/a/apparent_power.elisa) |
| Nim | [`nim/a/apparent_power.nim`](../../../nim/a/apparent_power.nim) |
| Odin | [`odin/a/apparent_power.odin`](../../../odin/a/apparent_power.odin) |
| Rust | [`rust/a/apparent_power.rs`](../../../rust/a/apparent_power.rs) |
| V | [`v/a/apparent_power.v`](../../../v/a/apparent_power.v) |
| Zig | [`zig/a/apparent_power.zig`](../../../zig/a/apparent_power.zig) |

## Pinned source

- [TheAlgorithms Python `apparent_power.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/apparent_power.py)
