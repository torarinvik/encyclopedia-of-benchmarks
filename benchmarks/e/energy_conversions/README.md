# Energy conversions

Convert a bounded energy value between the 13 units in the pinned Python source. The package keeps the source factor constants and evaluates the conversion as `(value * from_factor) / to_factor`.

## Contract

- Uses the `float64_triple` ABI with inputs `[value, from_code, to_code]`.
- `value` must be finite and in `[-1,000,000, 1,000,000]`.
- Unit codes must be exact integral binary64 values from `0` through `12`, in the source dictionary's insertion order.
- Valid inputs return `value * source_factor / target_factor` in that operation order. Invalid values or codes return `-1e300`.
- A valid result cannot equal the invalid sentinel under the bounded input contract.

| Code | Unit | Source factor |
|---:|---|---:|
| 0 | joule | 1.0 |
| 1 | kilojoule | 1,000.0 |
| 2 | megajoule | 1,000,000.0 |
| 3 | gigajoule | 1,000,000,000.0 |
| 4 | wattsecond | 1.0 |
| 5 | watthour | 3,600.0 |
| 6 | kilowatthour | 3,600,000.0 |
| 7 | newtonmeter | 1.0 |
| 8 | calorie_nutr | 4,186.8 |
| 9 | kilocalorie_nutr | 4,186,800.00 |
| 10 | electronvolt | 1.602176634e-19 |
| 11 | britishthermalunit_it | 1,055.05585 |
| 12 | footpound | 1.355818 |

The pinned [Python `energy_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/energy_conversions.py) checks both unit names, then returns `value * ENERGY_CONVERSION[from_type] / ENERGY_CONVERSION[to_type]`. This benchmark maps the fixed unit-name set to numeric codes and defines bounded invalid-input behavior for the ABI.

## Workload and ABI

[`workload.json`](workload.json) covers every source and destination unit, source examples, negative and boundary values, and invalid or fractional unit codes. Results use input-scaled tolerance `1e-12`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm energy_conversions --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/e/energy_conversions/rust/build.json
python3 benchmarks/verify_energy_conversions.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```
