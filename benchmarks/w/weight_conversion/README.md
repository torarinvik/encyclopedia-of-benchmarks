# Weight conversion

Convert a bounded value between the weight units in the pinned Python source.
The implementation preserves the source's separate input and output factor
tables and evaluates `value * KILOGRAM_CHART[to_type] * WEIGHT_TYPE_CHART[from_type]`.

## Contract

- Uses the `float64_triple` ABI with inputs `[value, from_code, to_code]`.
- `value` must be finite and in `[-1,000,000, 1,000,000]`.
- Unit codes must be exact integral binary64 values from `0` through `10`, in
  the pinned Python chart insertion order.
- Valid inputs return the result of multiplying the value by the destination
  `KILOGRAM_CHART` factor and then by the source `WEIGHT_TYPE_CHART` factor.
- Invalid values or codes return `-1e300`. A valid result cannot equal this
  sentinel under the bounded input contract.

| Code | Unit | Destination factor | Source factor |
|---:|---|---:|---:|
| 0 | kilogram | 1.0 | 1.0 |
| 1 | gram | 1,000.0 | 0.001 |
| 2 | milligram | 1,000,000.0 | 0.000001 |
| 3 | metric-ton | 0.001 | 1,000.0 |
| 4 | long-ton | 0.0009842073 | 1,016.04608 |
| 5 | short-ton | 0.0011023122 | 907.184 |
| 6 | pound | 2.2046244202 | 0.453592 |
| 7 | stone | 0.1574731728 | 6.35029 |
| 8 | ounce | 35.273990723 | 0.0283495 |
| 9 | carrat | 5,000.0 | 0.0002 |
| 10 | atomic-mass-unit | 6.022136652e26 | 1.660540199e-27 |

The pinned [Python `weight_conversion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/weight_conversion.py)
supports all eleven units, including its spelling `carrat`. The pinned
[Julia implementation](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/conversions/weight_conversion.jl)
has the same two factor tables and formula for the ten shared units, but omits
`stone`. Numeric codes normalize unit names for the benchmark; for Julia,
`stone` is outside the source's supported domain.

## Workload and ABI

[`workload.json`](workload.json) covers all source/destination pairs, source
examples, negative and boundary values, and invalid unit codes. Results use an
input-scaled tolerance of `1e-12`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm weight_conversion --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/w/weight_conversion/rust/build.json
```
