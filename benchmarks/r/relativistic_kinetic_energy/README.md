# Relativistic Kinetic Energy

This benchmark ports the pinned Python calculation of kinetic energy using the Lorentz factor. It returns energy in joules.

## Contract

- The `i64_array_float64` ABI supplies exactly `[mass_kg, velocity_m_per_s]` as signed 64-bit integers.
- Mass must be in `[0, 1,000,000]` kg. Velocity must be in `[-299792457, 299792457]` m/s, using `c = 299792458` m/s. This integer-valued subset keeps the packed inputs exact and excludes `|velocity| >= c`, where the source expression is singular or outside the real domain.
- Preserve the source expression order: `gamma = 1 / sqrt(1 - (velocity**2 / c**2))`, then `(gamma - 1) * mass * c**2`. A negative velocity is squared, so it gives the same result as its positive counterpart. Zero mass or zero velocity gives zero.
- Malformed inputs or values outside the contract return `-1e300`. Results use relative and absolute tolerance `1e-12`.

The source imports `c` from `scipy.constants`; its value is exactly 299792458 m/s. This formula differs from the classical `kinetic_energy` benchmark, which uses `0.5 * mass * velocity^2`.

## Source

- [TheAlgorithms/Python `relativistic_kinetic_energy.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/relativistic_kinetic_energy.py)

## Workload and build

[`workload.json`](workload.json) covers the source examples, signed velocity symmetry, zero cases, a near-light-speed input, and invalid domain values. The source-backed expected-value check is in [`benchmarks/run_i64_array_float64.py`](../../run_i64_array_float64.py). Build with the `i64_array_float64` ABI and record with that runner.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm relativistic_kinetic_energy --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/r/relativistic_kinetic_energy/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/relativistic_kinetic_energy.c`](../../../c/r/relativistic_kinetic_energy.c) |
| C3 | [`c3/r/relativistic_kinetic_energy.c3`](../../../c3/r/relativistic_kinetic_energy.c3) |
| C++ | [`cpp/r/relativistic_kinetic_energy.cpp`](../../../cpp/r/relativistic_kinetic_energy.cpp) |
| Elisa | [`elisa/r/relativistic_kinetic_energy.elisa`](../../../elisa/r/relativistic_kinetic_energy.elisa) |
| Nim | [`nim/r/relativistic_kinetic_energy.nim`](../../../nim/r/relativistic_kinetic_energy.nim) |
| Odin | [`odin/r/relativistic_kinetic_energy.odin`](../../../odin/r/relativistic_kinetic_energy.odin) |
| Rust | [`rust/r/relativistic_kinetic_energy.rs`](../../../rust/r/relativistic_kinetic_energy.rs) |
| V | [`v/r/relativistic_kinetic_energy.v`](../../../v/r/relativistic_kinetic_energy.v) |
| Zig | [`zig/r/relativistic_kinetic_energy.zig`](../../../zig/r/relativistic_kinetic_energy.zig) |
