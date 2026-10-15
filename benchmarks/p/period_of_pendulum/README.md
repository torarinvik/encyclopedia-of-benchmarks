# Period of a Simple Pendulum

This package benchmarks the pinned [TheAlgorithms/Python closed-form approximation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/period_of_pendulum.py): `2 * pi * (length / g) ** 0.5`, with SciPy standard gravity `g = 9.80665` m/s². It models a simple pendulum at small oscillation amplitude.

The `i64_array_float64` ABI accepts exactly one signed integer in a one-element array: `[length]`. Length is bounded to 0..1,000, matching the source's nonnegative input rule while selecting an integral subset of its floating-point API. The ports divide length by gravity, raise the quotient to 0.5, then multiply by `2*pi`; zero returns 0. Invalid ABI inputs return -1e300.

This closed-form approximation is distinct from the separate RK4 pendulum simulation. Output is binary64 period in seconds. Runtime and auxiliary space are O(1).
