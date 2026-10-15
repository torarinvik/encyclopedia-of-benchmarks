# Ideal Gas Law Pressure

This package benchmarks the pressure calculation in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/ideal_gas_law.py): `pressure_of_gas_system(moles, kelvin, volume)` returns `moles * kelvin * 8.314462 / volume`.

The `i64_array_float64` ABI accepts exactly three signed integers in this order: `[moles, kelvin, volume]`. Moles and kelvin are each in 0..1,000; volume is in 1..1,000. These bounds select an exact integer input subset of the source's floating-point API. The operation order and universal gas constant, 8.314462, are preserved. The source rejects negative inputs and divides by volume, so zero volume is excluded. Invalid ABI inputs return -1e300.

The output is binary64 pressure in pascals. Runtime and auxiliary space are O(1).
