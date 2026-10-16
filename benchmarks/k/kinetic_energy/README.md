# Kinetic Energy

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/kinetic_energy.py), which returns `0.5 * mass * abs(velocity) * abs(velocity)`.

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[mass, velocity]`. Mass is bounded to 0..1,000 and velocity to -1,000..1,000. These limits define an integral subset of the Python function's floating-point inputs and keep all results finite. Ports preserve the source's absolute-value handling and multiplication order. Invalid lengths or values return -1e300.

The result is kinetic energy in joules. This classical formula is distinct from the relativistic kinetic-energy calculation. Runtime and auxiliary space are O(1).

## Verification

Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_kinetic_energy.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/k/kinetic_energy.c](../../../c/k/kinetic_energy.c) |
| C3 | [c3/k/kinetic_energy.c3](../../../c3/k/kinetic_energy.c3) |
| C++ | [cpp/k/kinetic_energy.cpp](../../../cpp/k/kinetic_energy.cpp) |
| Elisa | [elisa/k/kinetic_energy.elisa](../../../elisa/k/kinetic_energy.elisa) |
| Nim | [nim/k/kinetic_energy.nim](../../../nim/k/kinetic_energy.nim) |
| Odin | [odin/k/kinetic_energy.odin](../../../odin/k/kinetic_energy.odin) |
| Rust | [rust/k/kinetic_energy.rs](../../../rust/k/kinetic_energy.rs) |
| V | [v/k/kinetic_energy.v](../../../v/k/kinetic_energy.v) |
| Zig | [zig/k/kinetic_energy.zig](../../../zig/k/kinetic_energy.zig) |
