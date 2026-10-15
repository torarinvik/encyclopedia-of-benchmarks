# Pressure unit conversion

Converts a pressure value between units using the pinned Rust conversion factors. The source resolves a source and destination unit, converts the input to pascals, then converts from pascals to the destination unit.

## Contract

- Uses the `float64_triple` ABI with inputs `[value, from_unit_code, to_unit_code]`.
- The value is finite and in `[-1,000,000, 1,000,000]`.
- Unit codes are exact integral binary64 values: `0` Pascal, `1` kilopascal, `2` megapascal, `3` bar, `4` atmosphere, and `5` psi.
- Returns `value * from_factor / to_factor`, with the multiplication performed before division. Invalid values or codes return `-1.0`.
- Since negative pressure values are accepted, `-1.0` can also be a valid conversion result (for example, `-1000` pascals to kilopascals). The inputs determine whether the sentinel denotes invalidity.
- Results use input-scaled tolerance `1e-12`.

The chosen factors are copied from Rust's `PressureUnit::to_pascal_factor`: `1`, `1000`, `1,000,000`, `100,000`, `101,325`, and `6894.757293168`. The bounded value and unit set keep every output finite and within `1e12` in magnitude.

## Source semantics and variants

The benchmark follows pinned [TheAlgorithms Rust `src/conversions/pressure.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/pressure.rs). Its public function takes `(value, from_unit, to_unit)`, accepts enum values or unit strings, computes `pascals = value * from_factor`, and returns `pascals / to_factor`. Negative finite pressures are accepted by the source and remain valid here. The source returns an error for unknown unit names; the numeric ABI maps unknown or fractional unit codes to `-1.0`. It does not explicitly reject NaN or infinity, while this benchmark limits inputs to finite values.

The Python `pressure_conversions` candidate supports the same broad conversion task but uses rounded, separately tabulated multipliers and multiplies both factors. Its numeric results can differ from Rust's; it is a distinct source variant and is not used as an exact oracle for this package.

## Workload and runner integration

[`workload.json`](workload.json) covers common conversions, same-unit conversion, negative values including a valid result equal to the invalid sentinel, the input bound, and invalid unit codes. Build with `float64_triple` and record with `benchmarks/run_float64_triple.py`.

