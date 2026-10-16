# Reynolds Number

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/reynolds_number.py), which returns `(density * abs(velocity) * diameter) / viscosity`.

The `i64_array_float64` ABI accepts exactly four signed integers in this order: `[density, velocity, diameter, viscosity]`. Density, diameter, and viscosity are bounded to 1..1,000, matching the source positivity guards. Velocity is bounded to -1,000..1,000; the source uses its absolute value, so either sign is valid. The bounds keep intermediate products finite and preserve the source multiplication and division order. Invalid ABI inputs return -1e300.

The output is binary64 and dimensionless. Runtime and auxiliary space are O(1).

## Build and verification

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm reynolds_number --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/r/reynolds_number/rust/build.json
python3 benchmarks/verify_reynolds_number.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The verifier checks a bounded oracle corpus and verifies the workload records without changing the formula's operation order.
