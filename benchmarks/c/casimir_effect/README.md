# Casimir Effect

This package follows the pinned [TheAlgorithms/Python `casimir_effect`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/casimir_effect.py). It solves for the one missing quantity in the ideal parallel-plate equation. The source requires exactly one of force, plate area, and plate distance to be zero, rejects negative inputs, and returns the missing quantity with its field name.

The `i64_array_float64` ABI accepts exactly `[force_pN, area_mm2, distance_um]`. The integer inputs encode pico-newtons, square millimeters, and micrometers; ports convert them to SI by multiplying by `1e-12`, `1e-6`, and `1e-6`, respectively. Every encoded value is in `0..1,000,000`, and exactly one must be zero. The scalar result is in SI units and corresponds to the missing field at the zero-valued input position: force in newtons, area in square meters, or distance in meters.

The ports preserve the source constants (`ℏ = 1.054571817e-34`, `c = 3e8`, and π) and each branch's arithmetic order. The scale bounds keep all intermediate and final values finite. Invalid layouts, negative or out-of-range values, and inputs with zero or multiple zero fields return `-1e300` under the benchmark ABI. The source's tuple field name is represented by the zero position, while the measured return is its numeric value.

Runtime and auxiliary space are O(1). The workload covers all three solution branches, SI scaling, and invalid inputs.

The shared float64 runner converts the packed units to SI and validates the source-ordered branch formula with the declared tolerances.
