# Gravitational Potential Energy

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/potential_energy.py), which returns `mass * g * height` using `scipy.constants.g` (9.80665 m/s²).

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[mass, height]`. Both values are bounded to 0..1,000, matching the source's nonnegative input rule while selecting an integral subset of its floating-point API. Gravity is fixed at the source constant 9.80665, and ports preserve the source multiplication order. Zero mass or height is valid. Invalid lengths and out-of-range values return -1e300.

The output is binary64 energy in joules. Runtime and auxiliary space are O(1).
