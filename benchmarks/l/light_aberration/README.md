# Light Aberration

This benchmark ports the pinned Python light-aberration angle conversion. It maps an angle measured in the moving frame to the corresponding angle in the observer frame.

## Contract

- The `i64_array_float64` ABI receives exactly `[theta_microrad, beta_ppm]`.
- Decode the angle as `theta_microrad / 1,000,000` radians and the velocity ratio as `beta_ppm / 1,000,000`.
- `theta_microrad` is in `[-3,141,592, 3,141,592]`, so the angle remains strictly inside `(-π, π)`; `beta_ppm` is in `[0, 999,999]`, so the velocity ratio is in `[0, 1)`.
- Preserve the source operation order: `factor = sqrt((1-beta)/(1+beta))`, then `2*atan(factor*tan(theta/2))`, then round to five decimal places using ties-to-even. The bounded domain keeps the tangent finite. Invalid shape or values return `-1e300`.
- To keep the rounded result stable across math libraries, outputs within `1e-12` radians of any five-decimal rounding midpoint are excluded: when `fraction = (angle*100000) - floor(angle*100000)`, `abs(fraction - 0.5) <= 1e-7` returns `-1e300`. This removes the discontinuity band while preserving the source formula and rounding on the rest of the domain.
- Results use absolute tolerance `5e-12` to account for binary64 math-library differences after decimal rounding.

The source's `round(..., 5)` rounds the exact binary64 result to the nearest five-decimal value, breaking exact ties toward an even final decimal integer. Ports extract the binary significand and exponent and perform that comparison with integer arithmetic, so rounding does not depend on an inexact `angle * 100000` intermediate. The midpoint exclusion is evaluated first using the stated guard. The input bounds keep every nonzero computed angle in the normal binary64 range and keep the integer rounding quotient small.

## Source

- [TheAlgorithms/Python `physics/light_aberration.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/light_aberration.py)

## Workload and build

[`workload.json`](workload.json) includes the pinned zero-velocity example, signed angles, high beta, and invalid values. Build with the `i64_array_float64` ABI and record with `benchmarks/run_i64_array_float64.py`.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm light_aberration --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/l/light_aberration/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm light_aberration
```

The source-based expected-value mapping is wired into `benchmarks/run_i64_array_float64.py` before recording.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/light_aberration.c`](../../../c/l/light_aberration.c) |
| C3 | [`c3/l/light_aberration.c3`](../../../c3/l/light_aberration.c3) |
| C++ | [`cpp/l/light_aberration.cpp`](../../../cpp/l/light_aberration.cpp) |
| Elisa | [`elisa/l/light_aberration.elisa`](../../../elisa/l/light_aberration.elisa) |
| Nim | [`nim/l/light_aberration.nim`](../../../nim/l/light_aberration.nim) |
| Odin | [`odin/l/light_aberration.odin`](../../../odin/l/light_aberration.odin) |
| Rust | [`rust/l/light_aberration.rs`](../../../rust/l/light_aberration.rs) |
| V | [`v/l/light_aberration.v`](../../../v/l/light_aberration.v) |
| Zig | [`zig/l/light_aberration.zig`](../../../zig/l/light_aberration.zig) |
