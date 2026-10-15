# Malus's Law

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/malus_law.py), which returns `initial_intensity * (cos(radians(angle)) ** 2)`.

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[initial_intensity, angle]`. Intensity is bounded to 0..1,000 and angle to 0..360 degrees. The angle range and nonnegative intensity preserve the source guards; the intensity cap and integral inputs are benchmark bounds over the source's floating-point API. Ports convert degrees to radians, square the cosine, then multiply by the initial intensity. Invalid lengths and out-of-contract values return -1e300 under the benchmark ABI; the source raises `ValueError` for negative intensity or angles outside [0, 360].

The output is binary64 transmitted intensity. A relative and absolute tolerance of 1e-12 accommodates small differences among system math libraries. Runtime and auxiliary space are O(1).
