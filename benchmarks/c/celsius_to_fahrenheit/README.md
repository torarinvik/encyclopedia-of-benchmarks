# Celsius to Fahrenheit

Convert one Celsius temperature to Fahrenheit using the pinned source's binary64 evaluation order: `(celsius * 9.0 / 5.0) + 32.0`.

## Contract

- The input is one finite IEEE 754 binary64 value in `[-1e100, 1e100]`.
- The result is compared with `absolute_error <= 1e-14 + 1e-15 * abs(expected)`. The absolute term handles cancellation near 0°F; the relative term covers larger magnitudes.
- The workload includes negative and positive temperatures, values around zero, and large finite magnitudes. The implementation does not use CPU-specific instructions or platform-specific libraries.

## Source and verification

The pinned [TheAlgorithms/C conversion](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/celsius_to_fahrenheit.c) computes the conversion as multiply by nine, divide by five, then add 32. The benchmark keeps that operation order in all nine language ports. Its expected results are rounded from an exact rational oracle over each binary64 input.

Build with the shared unary binary64 ABI and record with `benchmarks/run_float64_unary.py`:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm celsius_to_fahrenheit --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/c/celsius_to_fahrenheit/rust/build.json
```
