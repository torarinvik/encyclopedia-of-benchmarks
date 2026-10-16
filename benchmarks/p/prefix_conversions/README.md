# Prefix conversions

Convert an amount between SI prefixes or between binary prefixes. The package keeps the pinned Python source's two separate formulas and exponent tables.

## Contract

- Uses the `float64_triple` ABI with inputs `[known_amount, known_prefix_code, unknown_prefix_code]`.
- `known_amount` must be finite and in `[-1,000,000, 1,000,000]`.
- Codes `0`–`19` select SI prefixes. Codes `20`–`27` select binary prefixes. Both prefix codes in a call must belong to the same family.
- SI conversion returns `known_amount * 10 ** (known_exponent - unknown_exponent)`.
- Binary conversion returns `known_amount * 2 ** ((known_exponent - unknown_exponent) * 10)`.
- Invalid values, codes, or mixed families return `-1e300`. All valid results are finite within the bounded input domain.

SI codes follow the pinned `SIUnit` declaration order:

| Code | Prefix | Exponent |
|---:|---|---:|
| 0 | yotta | 24 |
| 1 | zetta | 21 |
| 2 | exa | 18 |
| 3 | peta | 15 |
| 4 | tera | 12 |
| 5 | giga | 9 |
| 6 | mega | 6 |
| 7 | kilo | 3 |
| 8 | hecto | 2 |
| 9 | deca | 1 |
| 10 | deci | -1 |
| 11 | centi | -2 |
| 12 | milli | -3 |
| 13 | micro | -6 |
| 14 | nano | -9 |
| 15 | pico | -12 |
| 16 | femto | -15 |
| 17 | atto | -18 |
| 18 | zepto | -21 |
| 19 | yocto | -24 |

Binary codes follow the pinned `BinaryUnit` declaration order:

| Code | Prefix | Exponent |
|---:|---|---:|
| 20 | yotta | 8 |
| 21 | zetta | 7 |
| 22 | exa | 6 |
| 23 | peta | 5 |
| 24 | tera | 4 |
| 25 | giga | 3 |
| 26 | mega | 2 |
| 27 | kilo | 1 |

The pinned [Python `prefix_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/prefix_conversions.py) accepts enum values or case-insensitive strings. Numeric codes represent those fixed enum entries; the benchmark adds finite bounds and an invalid-input sentinel for its ABI. The SI forms overlap partly with [`order_of_magnitude_conversion`](../../o/order_of_magnitude_conversion/README.md), while the binary-prefix operation remains separate.

## Workload and ABI

[`workload.json`](workload.json) covers every same-family prefix pair, both source examples, negative and boundary amounts, invalid codes, and mixed families. Its exhaustive pair grid uses a small nonzero amount so wide exponent gaps remain within the runner's input-scaled tolerance `1e-12`; ordinary source examples retain their original magnitudes.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm prefix_conversions --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/p/prefix_conversions/rust/build.json
```
