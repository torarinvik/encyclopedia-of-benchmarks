# Pressure conversions

Convert a bounded pressure value between the eight unit names supported by the pinned Python source. The package preserves its rounded source and destination factor tables and multiplication order.

## Contract

- Uses the `float64_triple` ABI with inputs `[value, from_code, to_code]`.
- `value` must be finite and in `[-1,000,000, 1,000,000]`.
- Unit codes are exact integral binary64 values: `0` atm, `1` pascal, `2` bar, `3` kilopascal, `4` megapascal, `5` psi, `6` inHg, and `7` torr.
- Return `(value * from_factor) * to_factor`, preserving the source's operation order. Invalid values or codes return `-1.0`.
- A valid conversion can also equal `-1.0` (for example, `-1` atm to atm); the inputs determine whether `-1.0` denotes invalidity.
- The source's rounded factors can make conversions inexact, including same-unit conversions.

The factor pairs `(from_factor, to_factor)` are: atm `(1, 1)`, pascal `(0.0000098, 101325)`, bar `(0.986923, 1.01325)`, kilopascal `(0.00986923, 101.325)`, megapascal `(9.86923, 0.101325)`, psi `(0.068046, 14.6959)`, inHg `(0.0334211, 29.9213)`, and torr `(0.00131579, 760)`.

## Source semantics and related algorithms

The pinned [Python `pressure_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/pressure_conversions.py) maps unit strings to these rounded factor pairs and computes `value * source.from_factor * target.to_factor`. This is a distinct source variant from the Rust `pressure` benchmark, which uses a different unit table and divides by the destination Pascal factor.

## Workload and ABI

[`workload.json`](workload.json) covers every unit code in conversions, the source's examples, negative values, both value bounds, and invalid/fractional codes. Results are compared with input-scaled tolerance `1e-12`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm pressure_conversions --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/p/pressure_conversions/rust/build.json
```
