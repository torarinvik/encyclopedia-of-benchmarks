# Temperature scale conversion

Convert a bounded value between the eight scales implemented by the pinned Rust source. The source converts to Kelvin first, then from Kelvin to the destination scale, preserving each formula's operation order.

## Contract

- The `float64_triple` ABI receives `[value, from_code, to_code]`.
- `value` must be finite and in `[-1,000,000, 1,000,000]`.
- Unit codes must be exact integer-valued binary64 values from 0 through 7: Kelvin, Celsius, Fahrenheit, Rankine, Delisle, Newton, Réaumur, and Rømer, respectively.
- Negative values are accepted on every scale, including below absolute zero, matching the source's algebraic formulas.
- Invalid values or unit codes return `-1e300`. Valid conversions may return `-1.0`.
- The input-scaled comparison tolerance is `1e-12`.

The conversion preserves the source's two-step formulas. For example, Celsius to Kelvin adds `273.15`; Fahrenheit to Kelvin computes `(value + 459.67) * 5 / 9`; Kelvin to Delisle computes `(373.15 - kelvin) * 3 / 2`.

## Source

Pinned Rust implementation: [`temperature.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/temperature.rs).

## Workload and ABI

[`workload.json`](workload.json) covers every destination from freezing Celsius, conversions back from every non-Celsius scale, negative values, the numeric bounds, and invalid unit codes.

Build and record with the `float64_triple` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm temperature --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/t/temperature/rust/build.json
python3 benchmarks/verify_temperature.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```
