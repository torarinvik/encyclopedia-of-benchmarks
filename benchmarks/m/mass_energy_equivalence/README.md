# Mass-Energy Equivalence

This package benchmarks both public operations in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/mass_energy_equivalence.py): `energy_from_mass(mass) = mass * c**2` and `mass_from_energy(energy) = energy / c**2`. The source uses the SI speed of light, `c = 299792458` m/s, and raises an error for negative inputs while returning zero for zero.

The `i64_array_float64` ABI accepts exactly `[operation, value]`. Operation 0 treats `value` as mass in kilograms and returns energy in joules. Operation 1 treats it as energy in joules and returns equivalent mass in kilograms. In either operation, value is bounded to 0..1,000,000,000. The bound is a finite exact-integer subset of the source's float input domain. Ports use the same `c**2` binary64 constant and preserve each formula's operation order. Invalid length, operation, or value returns -1e300.

The output is binary64 with relative and absolute tolerances of 1e-12. Runtime and auxiliary space are O(1).
