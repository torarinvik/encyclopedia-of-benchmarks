# Maxwell Scalar Methods

This package benchmarks seven independent numeric methods from the pinned Python Maxwell module. It uses an operation selector over the `i64_array_float64` ABI; each operation preserves one source function's scalar behavior. It does not combine the methods into a field simulation.

## Contract

The input is a packed signed 64-bit integer array. Its first value selects the operation, and every operation requires exactly the listed length:

| Op | Source method | Layout after the selector | Result |
| --- | --- | --- | --- |
| 0 | `gauss_law_electric` | `electric_field_1e12, surface_area_1e12, enclosed_charge_1e12, permittivity_1e18` | `1.0` when the source law check succeeds, otherwise `0.0` |
| 1 | `faraday_law` | `electric_circulation_1e12, magnetic_flux_change_rate_1e12` | `1.0` when the source law check succeeds, otherwise `0.0` |
| 2 | `ampere_maxwell_law` | `magnetic_circulation_1e12, enclosed_current_1e12, electric_flux_change_rate_1e6, permeability_1e18, permittivity_1e18` | `1.0` when the source law check succeeds, otherwise `0.0` |
| 3 | `electromagnetic_wave_speed` | `permeability_1e18, permittivity_1e18` | Wave speed |
| 4 | `electromagnetic_wave_impedance` | `permeability_1e18, permittivity_1e18` | Wave impedance |
| 5 | `poynting_vector_magnitude` | `electric_field_1e12, magnetic_field_1e12, permeability_1e18` | Source formula `(electric_field * magnetic_field) / permeability`, including its sign |
| 6 | `energy_density_electromagnetic` | `electric_field_1e12, magnetic_field_1e12, permittivity_1e18, permeability_1e18` | Electromagnetic energy density |

The `1e12` fields, areas, charges, currents, and circulations decode as `raw / 1e12`. The `1e6` electric-flux-change rate decodes as `raw / 1e6`. Constants with suffix `1e18` decode as `raw / 1e18`; zero selects that parameter's exact source default (`VACUUM_PERMITTIVITY` or `VACUUM_PERMEABILITY`). A nonzero custom constant must be in `[1,000,000, 1,000,000,000,000,000]`, which represents `[1e-12, 1e-3]`.

The common physical input raw range is `[-1,000,000,000,000,000, 1,000,000,000,000,000]`; surface area is nonnegative in that range. The Ampere-Maxwell flux-change-rate raw range is `[-1e18, 1e18]`. Operation lengths are exact. Valid inputs use at most six integers; the parser accepts up to seven so one trailing word is rejected as malformed. Unknown selectors, malformed layouts, and out-of-domain values return `-1e300`.

The three law checks retain the source tolerance: 1% of the absolute expected value, with an absolute tolerance of `1e-10` when the expected value is zero. The wave speed, impedance, Poynting, and energy-density methods preserve source formula order and use absolute and relative tolerances of `1e-12`. Bounds keep all valid results finite: wave speed is at most `1e12`, impedance at most `sqrt(1e9)`, absolute Poynting output at most `1e18`, and energy density at most approximately `5e17`.

`gauss_law_magnetic(surface_area)` is explicitly excluded. The pinned implementation returns true for every nonnegative area because it hard-codes magnetic flux to zero; it does not accept or inspect a magnetic-flux input, so it is only a constant-true placeholder rather than a flux-check algorithm.

## Workload and source

[`workload.json`](workload.json) covers all seven operation codes, source defaults, custom constants, positive and negative scalar inputs, law-check true/false cases, zero-expected tolerance cases, malformed layouts, and invalid constant/domain bounds. Expected results are defined in [`maxwells_equations_oracle.py`](../maxwells_equations_oracle.py).

The pinned source is [TheAlgorithms/Python `maxwells_equations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/maxwells_equations.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Language ports

- C: [c/m/maxwells_equations.c](../../c/m/maxwells_equations.c)
- C3: [c3/m/maxwells_equations.c3](../../c3/m/maxwells_equations.c3)
- C++: [cpp/m/maxwells_equations.cpp](../../cpp/m/maxwells_equations.cpp)
- Elisa: [elisa/m/maxwells_equations.elisa](../../elisa/m/maxwells_equations.elisa)
- Nim: [nim/m/maxwells_equations.nim](../../nim/m/maxwells_equations.nim)
- Odin: [odin/m/maxwells_equations.odin](../../odin/m/maxwells_equations.odin)
- Rust: [rust/m/maxwells_equations.rs](../../rust/m/maxwells_equations.rs)
- V: [v/m/maxwells_equations.v](../../v/m/maxwells_equations.v)
- Zig: [zig/m/maxwells_equations.zig](../../zig/m/maxwells_equations.zig)
