# Time conversions

Convert a nonnegative time value between the seven units in the pinned Python source. The package preserves the source's seconds factors, precomputed inverse factors, multiplication order, and rounding to three decimal places.

## Contract

- Uses the `float64_triple` ABI with inputs `[time_value, from_code, to_code]`.
- `time_value` must be finite and in `[0, 10,000]`.
- Unit codes are exact integral binary64 values from `0` through `6`, in the source dictionary insertion order.
- Valid inputs return `round((time_value * time_chart[from]) * time_chart_inverse[to], 3)`, using nearest-thousandth ties-to-even rounding. The ports use a fused multiply-add residual when the scaled value lands on an exact half-integer, so the original product’s side of the midpoint is preserved before rounding.
- Invalid values or codes return `-1e300`.

| Code | Unit | Seconds factor | Inverse factor |
|---:|---|---:|---:|
| 0 | seconds | 1.0 | 1.0 |
| 1 | minutes | 60.0 | 0.016666666666666666 |
| 2 | hours | 3,600.0 | 0.0002777777777777778 |
| 3 | days | 86,400.0 | 1.1574074074074073e-05 |
| 4 | weeks | 604,800.0 | 1.6534391534391535e-06 |
| 5 | months | 2,629,800.0 | 3.802570537683474e-07 |
| 6 | years | 31,557,600.0 | 3.168808781402895e-08 |

The pinned [Python `time_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/time_conversions.py) uses 2,629,800 seconds per approximate month and 31,557,600 per year, computes a separate reciprocal for each target unit, then rounds the product to three decimal places.

## Workload and ABI

[`workload.json`](workload.json) covers all 49 ordered unit pairs, the source's representative examples, zero and both value bounds, and invalid, negative, fractional-code, or out-of-range inputs. Added edge cases cover the half-millisecond boundary immediately below, at, and above the threshold, the 2.5-millisecond boundary, the reported 9-seconds-to-hours case, and half-millisecond results across the source and inverse factor paths. Results use input-scaled tolerance `1e-12`.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm time_conversions --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/t/time_conversions/rust/build.json
```
