# Speeds of gas molecules

This package ports the pinned molecular-speed formulas using bounded integer inputs and a binary64 result.

## Contract

Input is exactly `[operation, temperature_mK, molar_mass_micro]`. Operation `0` returns the average molecular speed and operation `1` returns the most probable speed. Temperature is in millikelvin from 0 to 1,000,000; molar mass is in micro-kilograms per mole from 1 to 1,000,000,000. The input may contain up to one trailing value for malformed-input coverage, but valid calls have exactly three values. Invalid input returns `-1e300`.

The computation converts temperature by dividing by 1,000 and molar mass by 1,000,000, then applies the source's formula with `R = 8.31446261815324`, binary64 π, and exponent `0.5`. Output comparisons use absolute and relative tolerances of `1e-12`.

Pinned source: [speeds_of_gas_molecules.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/speeds_of_gas_molecules.py). See [workload](workload.json) and [oracle](../../speeds_of_gas_molecules_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/s/speeds_of_gas_molecules.c |
| C3 | ../../../c3/s/speeds_of_gas_molecules.c3 |
| C++ | ../../../cpp/s/speeds_of_gas_molecules.cpp |
| Elisa | ../../../elisa/s/speeds_of_gas_molecules.elisa |
| Nim | ../../../nim/s/speeds_of_gas_molecules.nim |
| Odin | ../../../odin/s/speeds_of_gas_molecules.odin |
| Rust | ../../../rust/s/speeds_of_gas_molecules.rs |
| V | ../../../v/s/speeds_of_gas_molecules.v |
| Zig | ../../../zig/s/speeds_of_gas_molecules.zig |
