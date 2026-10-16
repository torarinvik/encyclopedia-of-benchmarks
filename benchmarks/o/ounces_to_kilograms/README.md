# Ounces to kilograms

This benchmark ports the pinned JavaScript conversion using its exact coefficient and multiplication-then-division order.

## Contract

- Uses the one-input binary64 ABI: `double ounces_to_kilograms(double ounces)`.
- The bounded domain is finite `ounces` in `[-1,000,000, 1,000,000]`.
- Return `(ounces * 28.3498) / 1000.0` in that operation order.
- Inputs outside the bound map to `-1e300`.
- Compare with relative and absolute tolerances of `1e-12`.

The source accepts a JavaScript number without validation. This benchmark bounds the input to keep the shared scalar contract finite while preserving its signed conversion formula. It deliberately retains the source's `28.3498` coefficient.

## Workload and build

[`workload.json`](workload.json) covers zero, fractional, negative, source-example, boundary, and out-of-range inputs. Build and record with the `float64_unary` ABI family:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm ounces_to_kilograms --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/o/ounces_to_kilograms/rust/build.json
```

The nine ports are under `c/o/`, `c3/o/`, `cpp/o/`, `elisa/o/`, `nim/o/`, `odin/o/`, `rust/o/`, `v/o/`, and `zig/o/`.

## Reviewed source

The pinned [TheAlgorithms JavaScript `OuncesToKilograms.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/OuncesToKilograms.js) returns `(oz * 28.3498) / 1000`. This coefficient differs from the existing weight conversion chart, so the candidate is a separate benchmark.
