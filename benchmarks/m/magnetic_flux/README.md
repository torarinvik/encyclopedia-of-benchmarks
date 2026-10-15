# Magnetic Flux

This package follows the pinned [TheAlgorithms/Python `magnetic_flux`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/magnetic_flux.py). It computes `round(magnetic_field * area * cos(radians(angle)), 1)`, where the angle is in degrees and the resulting flux has units of webers (equivalently tesla square meters).

The `i64_array_float64` ABI accepts exactly `[magnetic_field_tesla, area_m2, angle_degrees]`. Field and area are integers in `0..10,000`; zero is accepted by the source. The angle is restricted to `{0, 60, 90, 120, 180}`, a bounded subset of the source's inclusive 0–180 degree range. For these angles, outputs are integral or half-integral (the 90-degree result rounds to zero), so the source's one-decimal rounding is portable without ambiguous decimal halfway cases. Ports preserve the source multiplication order, degree-to-radian conversion, cosine, and rounding sequence.

Malformed layouts, negative or out-of-range field/area values, and unsupported angles return `-1e300`. The selected inputs keep flux finite and keep the right-angle cosine residual far below the one-decimal rounding threshold. This benchmark covers magnetic flux itself; no other current package implements this field-area-angle formula.

Runtime and auxiliary space are O(1). The workload covers the source examples, positive and negative flux, right-angle zero, zero-valued field/area, and invalid inputs.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm magnetic_flux --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/m/magnetic_flux/rust/build.json
```

The `i64_array_float64` runner validates the bounded layout and checks the pinned rounded flux formula.
