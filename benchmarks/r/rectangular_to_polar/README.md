# rectangular_to_polar

This package follows the pinned [TheAlgorithms/Rust `src/conversions/rectangular_to_polar.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/rectangular_to_polar.rs) as the canonical reference and compares it with [TheAlgorithms/Python `conversions/rectangular_to_polar.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/rectangular_to_polar.py). It is distinct from [`cartesian_to_polar`](../cartesian_to_polar/README.md), which returns an unrounded angle in radians. This package returns an angle in degrees and rounds both outputs to two decimals.

## Contract

- The `float64_triple` input is `[real, imag, component]`. Coordinates must be finite and within `[-1,000,000, 1,000,000]`. Selector `0` returns the magnitude; selector `1` returns the angle in degrees. Other selectors or invalid coordinates return `-1e300`.
- Magnitude is `round_to_two_decimals(sqrt(real * real + imag * imag))`. Angle is `round_to_two_decimals(degrees(atan2(imag, real)))` and ranges from `-180` to `180`. The origin uses the source's `atan2` result: positive zero for `(0,0)` and signed-zero behavior for signed-zero inputs.
- The pinned Rust helper defines `round_to_two_decimals(value)` as `(value * 100).round() / 100`, where ties round away from zero. The ports use that Rust behavior as the canonical tie rule. Python's built-in `round(value, 2)` uses ties to even and can differ on exact decimal midpoints; its documented examples agree with the canonical workload.
- The bounded coordinate range keeps the square and radius finite. The invalid sentinel cannot collide with any valid output.

The workload includes both components for every source example, axis and origin behavior, signed zero, quadrant angles, the maximum bounded radius, and invalid inputs. The independent oracle is [`benchmarks/rectangular_to_polar_oracle.py`](../../rectangular_to_polar_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rectangular_to_polar.c`](../../../c/r/rectangular_to_polar.c) |
| C3 | [`c3/r/rectangular_to_polar.c3`](../../../c3/r/rectangular_to_polar.c3) |
| C++ | [`cpp/r/rectangular_to_polar.cpp`](../../../cpp/r/rectangular_to_polar.cpp) |
| Elisa | [`elisa/r/rectangular_to_polar.elisa`](../../../elisa/r/rectangular_to_polar.elisa) |
| Nim | [`nim/r/rectangular_to_polar.nim`](../../../nim/r/rectangular_to_polar.nim) |
| Odin | [`odin/r/rectangular_to_polar.odin`](../../../odin/r/rectangular_to_polar.odin) |
| Rust | [`rust/r/rectangular_to_polar.rs`](../../../rust/r/rectangular_to_polar.rs) |
| V | [`v/r/rectangular_to_polar.v`](../../../v/r/rectangular_to_polar.v) |
| Zig | [`zig/r/rectangular_to_polar.zig`](../../../zig/r/rectangular_to_polar.zig) |
