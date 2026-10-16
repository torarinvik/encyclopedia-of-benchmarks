# Gravitational Potential Energy

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/potential_energy.py), which returns `mass * g * height` using `scipy.constants.g` (9.80665 m/s²).

The `i64_array_float64` ABI accepts exactly two signed integers in this order: `[mass, height]`. Both values are bounded to 0..1,000, matching the source's nonnegative input rule while selecting an integral subset of its floating-point API. Gravity is fixed at the source constant 9.80665, and ports preserve the source multiplication order. Zero mass or height is valid. Invalid lengths and out-of-range values return -1e300.

The output is binary64 energy in joules, with absolute tolerance 1e-9 and relative tolerance 1e-12. Runtime and auxiliary space are O(1).

## Verification

Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_potential_energy.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/potential_energy.c](../../../c/p/potential_energy.c) |
| C3 | [c3/p/potential_energy.c3](../../../c3/p/potential_energy.c3) |
| C++ | [cpp/p/potential_energy.cpp](../../../cpp/p/potential_energy.cpp) |
| Elisa | [elisa/p/potential_energy.elisa](../../../elisa/p/potential_energy.elisa) |
| Nim | [nim/p/potential_energy.nim](../../../nim/p/potential_energy.nim) |
| Odin | [odin/p/potential_energy.odin](../../../odin/p/potential_energy.odin) |
| Rust | [rust/p/potential_energy.rs](../../../rust/p/potential_energy.rs) |
| V | [v/p/potential_energy.v](../../../v/p/potential_energy.v) |
| Zig | [zig/p/potential_energy.zig](../../../zig/p/potential_energy.zig) |
