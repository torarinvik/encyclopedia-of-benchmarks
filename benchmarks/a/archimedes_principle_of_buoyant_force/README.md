# Archimedes Principle of Buoyant Force

Ports the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/archimedes_principle_of_buoyant_force.py), which returns buoyant force as `fluid_density * gravity * volume`.

The `i64_array_float64` ABI takes exactly two signed integer values in the order `[fluid_density, volume]`. Both values are bounded to 1..1,000. The optional gravity parameter is fixed at the pinned source default, 9.80665 m/s², and the expression order is preserved. The output is binary64 with absolute tolerance 1e-9 and relative tolerance 1e-12. The source rejects nonpositive density and volume; invalid lengths and out-of-range values map to -1e300.

This is an integral input subset of the Python API, which accepts floating-point density and volume. The bounds keep input multiplication small and finite. Runtime and auxiliary space are O(1).

## Verification

Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_archimedes_principle_of_buoyant_force.py
```

## Ports

| Language | Source |
| --- | --- |
| C | [c/a/archimedes_principle_of_buoyant_force.c](../../../c/a/archimedes_principle_of_buoyant_force.c) |
| C3 | [c3/a/archimedes_principle_of_buoyant_force.c3](../../../c3/a/archimedes_principle_of_buoyant_force.c3) |
| C++ | [cpp/a/archimedes_principle_of_buoyant_force.cpp](../../../cpp/a/archimedes_principle_of_buoyant_force.cpp) |
| Elisa | [elisa/a/archimedes_principle_of_buoyant_force.elisa](../../../elisa/a/archimedes_principle_of_buoyant_force.elisa) |
| Nim | [nim/a/archimedes_principle_of_buoyant_force.nim](../../../nim/a/archimedes_principle_of_buoyant_force.nim) |
| Odin | [odin/a/archimedes_principle_of_buoyant_force.odin](../../../odin/a/archimedes_principle_of_buoyant_force.odin) |
| Rust | [rust/a/archimedes_principle_of_buoyant_force.rs](../../../rust/a/archimedes_principle_of_buoyant_force.rs) |
| V | [v/a/archimedes_principle_of_buoyant_force.v](../../../v/a/archimedes_principle_of_buoyant_force.v) |
| Zig | [zig/a/archimedes_principle_of_buoyant_force.zig](../../../zig/a/archimedes_principle_of_buoyant_force.zig) |
