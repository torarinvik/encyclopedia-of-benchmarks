# Root-Mean-Square Molecular Speed

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/rms_speed_of_molecule.py), which returns `(3 * 8.3144598 * temperature / molar_mass) ** 0.5` using its universal gas constant `8.3144598`.

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[temperature, molar_mass]`. Temperature is bounded to 0..1,000 and molar mass to 1..1,000. These are benchmark bounds over the source's floating-point API; nonnegative temperature and positive molar mass preserve its guards. Ports preserve the constant, operation order, and half-power; zero temperature returns 0. Invalid lengths and out-of-contract values return -1e300 under the benchmark ABI, while the source raises exceptions for negative temperature or nonpositive molar mass.

The output is binary64 root-mean-square speed in metres per second. Runtime and auxiliary space are O(1).
