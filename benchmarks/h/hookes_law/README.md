# Hooke's Law

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/hookes_law.py), which calculates spring restoring force as `-spring_constant * displacement`.

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[spring_constant, displacement]`. The spring constant is bounded to 1..1,000, matching the source's positive-value guard. Displacement is bounded to -1,000..1,000; negative values represent compression or extension in the opposite direction and remain valid. Ports preserve the source unary-negation and multiplication order. Invalid ABI lengths and values return -1e300; this sentinel is a benchmark ABI rule, while the source raises an exception for a nonpositive spring constant.

The source's doctests use fractional displacements, while this ABI deliberately restricts both inputs to integers. Workload cases use integral values in the same formula, including a unit-displacement case corresponding to the source's 50 N/m example.

This benchmark has no equivalent hooke or restoring-force alias in the candidate catalog or existing benchmark tree. The output is binary64 force in newtons. Runtime and auxiliary space are O(1).
