# Graham's law of effusion

This package preserves all five numerical solvers in the pinned Python source: effusion ratio, first and second effusion rates, and first and second molar masses. Each operation uses the source formula and Python's six-decimal rounding on the bounded input domain.

## Contract

The `i64_array_float64` input stores `[operation, binary64_bits...]`. Signed 64-bit values after the operation code are the bit patterns of finite positive binary64 operands. Operation 0 is `[0, molar_mass_1, molar_mass_2]`; operations 1 and 2 are `[operation, effusion_rate, molar_mass_1, molar_mass_2]`; operations 3 and 4 are `[operation, molar_mass, effusion_rate_1, effusion_rate_2]`. Operands are bounded to `1e-6..1e6`. The rounded result must be at most `1e6`, and the fractional part of the unrounded result scaled by `1e6` must be outside the inclusive interval `[0.499, 0.501]`. This keeps the accepted domain away from binary64 rounding-boundary differences while preserving Python's six-decimal output. Invalid operations, shapes, operands, and out-of-domain results return `-1e300`.

| Operation | Source function | Formula |
|---:|---|---|
| 0 | `effusion_ratio` | `sqrt(molar_mass_2 / molar_mass_1)` |
| 1 | `first_effusion_rate` | `rate * sqrt(molar_mass_2 / molar_mass_1)` |
| 2 | `second_effusion_rate` | `rate / sqrt(molar_mass_2 / molar_mass_1)` |
| 3 | `first_molar_mass` | `molar_mass / pow(rate_1 / rate_2, 2)` |
| 4 | `second_molar_mass` | `pow(rate_1 / rate_2, 2) / molar_mass` |

Pinned source: [TheAlgorithms/Python `physics/grahams_law.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/grahams_law.py).

## Build and verification

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm grahams_law --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/g/grahams_law/rust/build.json
python3 benchmarks/verify_grahams_law.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/g/grahams_law.c`](../../../c/g/grahams_law.c) |
| C3 | [`c3/g/grahams_law.c3`](../../../c3/g/grahams_law.c3) |
| C++ | [`cpp/g/grahams_law.cpp`](../../../cpp/g/grahams_law.cpp) |
| Elisa | [`elisa/g/grahams_law.elisa`](../../../elisa/g/grahams_law.elisa) |
| Nim | [`nim/g/grahams_law.nim`](../../../nim/g/grahams_law.nim) |
| Odin | [`odin/g/grahams_law.odin`](../../../odin/g/grahams_law.odin) |
| Rust | [`rust/g/grahams_law.rs`](../../../rust/g/grahams_law.rs) |
| V | [`v/g/grahams_law.v`](../../../v/g/grahams_law.v) |
| Zig | [`zig/g/grahams_law.zig`](../../../zig/g/grahams_law.zig) |
