# Archimedes Principle of Buoyant Force

Ports the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/archimedes_principle_of_buoyant_force.py), which returns buoyant force as `fluid_density * gravity * volume`.

The `i64_array_float64` ABI takes exactly two signed integer values in the order `[fluid_density, volume]`. Both values are bounded to 1..1,000. The optional gravity parameter is fixed at the pinned source default, 9.80665 m/s², and the expression order is preserved. The output is binary64. The source rejects nonpositive density and volume; invalid lengths and out-of-range values map to -1e300.

This is an integral input subset of the Python API, which accepts floating-point density and volume. The bounds keep input multiplication small and finite. Runtime and auxiliary space are O(1).
